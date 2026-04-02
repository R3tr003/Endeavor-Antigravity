import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { getFirestore } from "firebase-admin/firestore";
import { GoogleGenAI } from "@google/genai";
import { checkRateLimit } from "./rateLimiter";

const googleAIApiKey = defineSecret("GOOGLE_GENAI_API_KEY");

// ─────────────────────────────────────────────────────────────────────────────
// SHARED HELPER – usata sia dal trigger che dalla callable
// ─────────────────────────────────────────────────────────────────────────────

async function classifyConversation(conversationId: string, apiKey: string): Promise<{
  isSpam: boolean;
  reason: string;
  alreadyFiltered: boolean;
}> {
  const messagingDb = getFirestore("messaging");
  const defaultDb = getFirestore();

  const convRef = messagingDb.collection("conversations").doc(conversationId);
  const convSnap = await convRef.get();
  if (!convSnap.exists) return { isSpam: false, reason: "", alreadyFiltered: false };

  const convData = convSnap.data()!;
  const isAlreadyFiltered = convData.isFiltered as boolean ?? false;

  // Recupera tutti i messaggi non-system
  const messagesSnap = await messagingDb
    .collection("conversations")
    .doc(conversationId)
    .collection("messages")
    .orderBy("createdAt", "asc")
    .get();

  const allMessages = messagesSnap.docs
    .filter(doc => !doc.data().isSystemMessage)
    .map(doc => ({
      senderId: doc.data().senderId as string,
      text: (doc.data().text as string) || "",
    }))
    .filter(m => m.text.trim().length > 0);

  if (allMessages.length < 1) return { isSpam: false, reason: "", alreadyFiltered: isAlreadyFiltered };

  // Il mittente originale è chi ha inviato il primo messaggio
  const originalSenderId = allMessages[0].senderId;

  // Contesto mittente
  let senderContext = "";
  try {
    const senderDoc = await defaultDb.collection("users").doc(originalSenderId).get();
    if (senderDoc.exists) {
      const s = senderDoc.data()!;
      senderContext = `Sender: ${s.firstName ?? ""} ${s.lastName ?? ""}, Role: ${s.role ?? ""}, Type: ${s.userType ?? ""}`;
    }
  } catch (_) {}

  const conversationTranscript = allMessages
    .map(m => `[${m.senderId === originalSenderId ? "SENDER" : "RECIPIENT"}]: ${m.text}`)
    .join("\n");

  const ai = new GoogleGenAI({ apiKey });

  const prompt = `You are a spam filter for a professional entrepreneur network app called Endeavor.
Analyze the FULL conversation transcript and determine if the sender's intent is legitimate or spam/inappropriate.

${senderContext}

FULL CONVERSATION TRANSCRIPT:
${conversationTranscript}

ALLOWED (legitimate):
- Advice requests with clear professional context
- Partnership exploration between entrepreneurs
- Expertise-specific questions
- Mentorship inquiries
- Professional introductions relevant to the Endeavor network
- Follow-ups on previous professional discussions

FILTER OUT (spam):
- Product or service sales pitches
- Generic cold outreach with no relevance to entrepreneurship
- Promotional content or advertisements
- Requests completely unrelated to business/entrepreneurship
- Suspicious or potentially harmful content
- Repeated attempts to sell after being ignored

IMPORTANT: Be conservative. Only flag as spam when confident (>0.80). When in doubt, allow.

Respond ONLY with a valid JSON object, no markdown, no explanation:
{
  "isSpam": boolean,
  "reason": "brief reason in English, max 8 words",
  "confidence": number between 0.0 and 1.0
}`;

  try {
    const result = await ai.models.generateContent({
      model: "gemini-2.5-flash",
      contents: prompt,
    });
    const clean = (result.text || "").trim().replace(/```json|```/g, "").trim();
    const parsed = JSON.parse(clean);
    const isSpam = parsed.isSpam === true && (parsed.confidence ?? 0) > 0.80;
    return { isSpam, reason: parsed.reason ?? "", alreadyFiltered: isAlreadyFiltered };
  } catch (e) {
    console.error("[classifyConversation] AI error:", e);
    return { isSpam: false, reason: "", alreadyFiltered: isAlreadyFiltered };
  }
}

// Applica il risultato della classificazione su Firestore
async function applyClassificationResult(
  conversationId: string,
  isSpam: boolean,
  reason: string,
  isAlreadyFiltered: boolean,
  isRecheck: boolean
): Promise<void> {
  const messagingDb = getFirestore("messaging");
  const convRef = messagingDb.collection("conversations").doc(conversationId);

  if (isSpam && !isAlreadyFiltered) {
    await convRef.update({
      isFiltered: true,
      filterReason: reason,
      filterCheckedAt: new Date(),
    });

    const systemMsgRef = messagingDb
      .collection("conversations")
      .doc(conversationId)
      .collection("messages")
      .doc();

    await systemMsgRef.set({
      senderId: "system",
      text: "ai_filter_warning",
      systemMessageType: "ai_filter_warning",
      createdAt: new Date(),
      readBy: [],
      deliveredTo: [],
      isSystemMessage: true,
    });

  } else if (!isSpam && isRecheck && isAlreadyFiltered) {
    await convRef.update({
      isFiltered: false,
      filterReason: "",
      filterCheckedAt: new Date(),
    });
  } else {
    // Aggiorna solo il timestamp del check
    await convRef.update({ filterCheckedAt: new Date() });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TRIGGER ESISTENTE – invariato nella logica, ora usa l'helper
// ─────────────────────────────────────────────────────────────────────────────

export const classifyMessage = onDocumentCreated(
  {
    document: "conversations/{conversationId}/messages/{messageId}",
    database: "messaging",
    region: "europe-west1",
    secrets: [googleAIApiKey],
  },
  async (event) => {
    const messageData = event.data?.data();
    if (!messageData) return;
    if (messageData.isSystemMessage === true) return;

    const conversationId = event.params.conversationId;
    const senderId = messageData.senderId as string;

    const messagingDb = getFirestore("messaging");
    const convSnap = await messagingDb.collection("conversations").doc(conversationId).get();
    if (!convSnap.exists) return;

    const convData = convSnap.data()!;
    const participantIds = convData.participantIds as string[];
    if (!participantIds.find((id: string) => id !== senderId)) return;

    // Conta messaggi non-system
    const messagesSnap = await messagingDb
      .collection("conversations")
      .doc(conversationId)
      .collection("messages")
      .get();

    const messageCount = messagesSnap.docs.filter(d => !d.data().isSystemMessage).length;
    const isFirstMessage = messageCount === 1;
    const isAlreadyFiltered = convData.isFiltered as boolean ?? false;
    const isRecheck = !isFirstMessage && messageCount % 10 === 0 && !isAlreadyFiltered;

    if (!isFirstMessage && !isRecheck) return;

    const { isSpam, reason, alreadyFiltered } = await classifyConversation(
      conversationId,
      googleAIApiKey.value()
    );

    console.log(`[classifyMessage] conv=${conversationId} isSpam=${isSpam} reason=${reason}`);
    await applyClassificationResult(conversationId, isSpam, reason, alreadyFiltered, isRecheck);
  }
);

// ─────────────────────────────────────────────────────────────────────────────
// NUOVA CALLABLE – riusa classifyConversation, zero duplicazione
// ─────────────────────────────────────────────────────────────────────────────

export const recheckConversation = onCall(
  {
    region: "europe-west1",
    secrets: [googleAIApiKey],
  },
  async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Unauthenticated");

    const { conversationId } = request.data as { conversationId: string };
    if (!conversationId) throw new HttpsError("invalid-argument", "Missing conversationId");

    // Rate limit: 5 calls per day per user
    await checkRateLimit(request.auth.uid, "recheckConversation", 5, 60 * 24);

    // Verifica che il richiedente sia partecipante
    const messagingDb = getFirestore("messaging");
    const convSnap = await messagingDb.collection("conversations").doc(conversationId).get();
    if (!convSnap.exists) return { filtered: false };

    const participantIds = convSnap.data()!.participantIds as string[];
    if (!participantIds.includes(request.auth.uid)) throw new HttpsError("permission-denied", "Forbidden");

    // 7-day cooldown per conversation: prevent rechecking too frequently
    const SEVEN_DAYS_MS = 7 * 24 * 60 * 60 * 1000;
    const filterCheckedAt = convSnap.data()!.filterCheckedAt as FirebaseFirestore.Timestamp | undefined;
    if (filterCheckedAt) {
      const lastCheckedMs = filterCheckedAt.toMillis();
      const elapsedMs = Date.now() - lastCheckedMs;
      if (elapsedMs < SEVEN_DAYS_MS) {
        const daysRemaining = Math.ceil((SEVEN_DAYS_MS - elapsedMs) / (24 * 60 * 60 * 1000));
        throw new HttpsError(
          "resource-exhausted",
          `This conversation was already checked recently. Please wait ${daysRemaining} more day(s) before rechecking.`
        );
      }
    }

    const { isSpam, reason, alreadyFiltered } = await classifyConversation(
      conversationId,
      googleAIApiKey.value()
    );

    console.log(`[recheckConversation] conv=${conversationId} isSpam=${isSpam} reason=${reason}`);
    await applyClassificationResult(conversationId, isSpam, reason, alreadyFiltered, true);

    return { filtered: isSpam, reason };
  }
);
