import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { defineSecret } from "firebase-functions/params";
import { getFirestore } from "firebase-admin/firestore";
import { GoogleGenAI } from "@google/genai";

const googleAIApiKey = defineSecret("GOOGLE_GENAI_API_KEY");

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

    // Ignora messaggi di sistema
    if (messageData.isSystemMessage === true) return;

    const conversationId = event.params.conversationId;
    const senderId = messageData.senderId as string;

    const messagingDb = getFirestore("messaging");
    const defaultDb = getFirestore();

    // Leggi la conversazione
    const convRef = messagingDb.collection("conversations").doc(conversationId);
    const convSnap = await convRef.get();
    if (!convSnap.exists) return;
    const convData = convSnap.data()!;

    const participantIds = convData.participantIds as string[];
    const recipientId = participantIds.find((id: string) => id !== senderId);
    if (!recipientId) return;

    // Recupera TUTTI i messaggi della conversazione
    const messagesSnap = await messagingDb
      .collection("conversations")
      .doc(conversationId)
      .collection("messages")
      .orderBy("createdAt", "asc")
      .get();

    const allMessages = messagesSnap.docs
      .filter(doc => !doc.data().isSystemMessage)
      .map(doc => {
        const d = doc.data();
        return {
          senderId: d.senderId as string,
          text: (d.text as string) || "",
        };
      })
      .filter(m => m.text.trim().length > 0);

    const messageCount = allMessages.length;

    // Regola di attivazione:
    // - Primo messaggio del mittente verso il destinatario
    // - Oppure ogni 10 messaggi se la conversazione era già approvata (re-check)
    const isFirstMessage = messageCount === 1;
    const isAlreadyFiltered = convData.isFiltered as boolean;
    const isRecheck = !isFirstMessage && messageCount % 10 === 0 && !isAlreadyFiltered;

    if (!isFirstMessage && !isRecheck) return;

    // Leggi il profilo del mittente per aggiungere contesto
    let senderContext = "";
    try {
      const senderDoc = await defaultDb.collection("users").doc(senderId).get();
      if (senderDoc.exists) {
        const s = senderDoc.data()!;
        senderContext = `Sender: ${s.firstName ?? ""} ${s.lastName ?? ""}, Role: ${s.role ?? ""}, Type: ${s.userType ?? ""}`;
      }
    } catch (_) {}

    // Costruisci la trascrizione completa della conversazione
    const conversationTranscript = allMessages
      .map(m => `[${m.senderId === senderId ? "SENDER" : "RECIPIENT"}]: ${m.text}`)
      .join("\n");

    // Classificazione con Gemini 2.0 Flash
    const ai = new GoogleGenAI({ apiKey: googleAIApiKey.value() });

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

    let isSpam = false;
    let reason = "";
    let confidence = 0;

    try {
      const result = await ai.models.generateContent({
        model: 'gemini-2.5-flash',
        contents: prompt
      });
      const responseText = (result.text || "").trim();
      // Rimuovi eventuale markdown se presente
      const clean = responseText.replace(/```json|```/g, "").trim();
      const parsed = JSON.parse(clean);
      isSpam = parsed.isSpam === true && (parsed.confidence ?? 0) > 0.80;
      reason = parsed.reason ?? "";
      confidence = parsed.confidence ?? 0;
      console.log(`[classifyMessage] conv=${conversationId} isSpam=${isSpam} confidence=${confidence} reason=${reason}`);
    } catch (e) {
      console.error("[classifyMessage] AI error:", e);
      return; // Fail-safe: in caso di errore non filtrare
    }

    if (isSpam) {
      // 1. Marca la conversazione come filtrata
      await convRef.update({
        isFiltered: true,
        filterReason: reason,
        filterCheckedAt: new Date(),
      });

      // 2. Inserisci messaggio di sistema visibile al mittente
      const systemText = "This message was flagged by Endeavor's AI filter as potentially promotional or irrelevant to our network's purpose.";
      const systemMsgRef = messagingDb
        .collection("conversations")
        .doc(conversationId)
        .collection("messages")
        .doc();

      await systemMsgRef.set({
        senderId: "system",
        text: systemText,
        createdAt: new Date(),
        readBy: [],
        deliveredTo: [],
        isSystemMessage: true,
      });

      console.log(`[classifyMessage] Filtered conv=${conversationId}, reason=${reason}`);

    } else if (isRecheck && isAlreadyFiltered) {
      // Re-check: se ora sembra legittima, togli il filtro
      await convRef.update({
        isFiltered: false,
        filterReason: "",
        filterCheckedAt: new Date(),
      });
      console.log(`[classifyMessage] Unfiltered conv=${conversationId} after recheck`);
    }
  }
);
