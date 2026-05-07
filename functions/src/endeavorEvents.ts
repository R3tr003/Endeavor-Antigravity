import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { getFirestore, FieldValue, Timestamp } from "firebase-admin/firestore";

const ENDEAVOR_SYSTEM_UID = "endeavor_system";

/**
 * Triggered when a Staff member updates an Endeavor event.
 *
 * - If the event is cancelled: sends a cancellation message to all participants.
 * - If the event title, date, or location changed: sends an update message.
 *
 * Messages are sent from the fixed "endeavor_system" UID in the messaging DB.
 * Each participant gets a message in their existing conversation with endeavor_system,
 * or a new conversation is created silently.
 *
 * All operations are idempotent via the `notifiedAt` timestamp field.
 */
export const notifyEndeavourEventChanges = onDocumentUpdated(
    {
        document: "events/{eventId}",
        region: "europe-west1",
    },
    async (event) => {
        if (!event.data) return;

        const before = event.data.before.data();
        const after = event.data.after.data();

        if (!before || !after) return;

        // Only care about endeavor_event type
        if (after.type !== "endeavor_event") return;

        const cancelled =
            before.status !== "cancelled" && after.status === "cancelled";
        const titleChanged =
            before.title !== after.title && after.status !== "cancelled";
        const dateChanged =
            before.startDate?.seconds !== after.startDate?.seconds &&
            after.status !== "cancelled";
        const locationChanged =
            before.location !== after.location && after.status !== "cancelled";

        const hasUpdate = titleChanged || dateChanged || locationChanged;

        if (!cancelled && !hasUpdate) return;

        const participantIds: string[] = after.participantIds ?? [];
        // Exclude the person who made the change — no point notifying the editor/deleter.
        const lastModifiedBy: string | undefined = after.lastModifiedBy;
        const recipients = participantIds.filter(
            (id) => id !== ENDEAVOR_SYSTEM_UID && id !== lastModifiedBy
        );
        if (recipients.length === 0) return;

        const db = getFirestore();
        const messagingDb = getFirestore(
            process.env.MESSAGING_DB_ID ?? "messaging"
        );

        let messageText: string;
        let notificationKey: string;

        if (cancelled) {
            messageText = `❌ The event "${after.title}" has been cancelled.`;
            notificationKey = "cancelNotifiedAt";
        } else {
            const changes: string[] = [];
            if (titleChanged)
                changes.push(`Title changed to "${after.title}"`);
            if (dateChanged) {
                const ts: Timestamp = after.startDate;
                changes.push(
                    `New date: ${ts.toDate().toISOString().slice(0, 16).replace("T", " ")} UTC`
                );
            }
            if (locationChanged)
                changes.push(
                    after.location
                        ? `Location: ${after.location}`
                        : "Location removed"
                );
            messageText = `📢 Update for "${after.title}":\n${changes.join("\n")}`;
            notificationKey = "updateNotifiedAt";
        }

        // Check idempotency — skip if we already sent this notification
        const eventRef = db
            .collection("events")
            .doc(event.data.after.ref.id);
        const freshSnap = await eventRef.get();
        const freshData = freshSnap.data();
        if (freshData?.[notificationKey]) return;

        // Mark as notified before sending to prevent double-sends
        await eventRef.update({ [notificationKey]: FieldValue.serverTimestamp() });

        // Send to each participant
        await Promise.all(
            recipients.map((userId) =>
                sendSystemMessageToUser(messagingDb, userId, messageText)
            )
        );
    }
);

async function sendSystemMessageToUser(
    messagingDb: FirebaseFirestore.Firestore,
    userId: string,
    text: string
): Promise<void> {
    try {
        const conversationId = await getOrCreateSystemConversation(
            messagingDb,
            userId
        );

        const batch = messagingDb.batch();
        const messageRef = messagingDb
            .collection("conversations")
            .doc(conversationId)
            .collection("messages")
            .doc();

        batch.set(messageRef, {
            senderId: ENDEAVOR_SYSTEM_UID,
            text,
            createdAt: FieldValue.serverTimestamp(),
            readBy: [ENDEAVOR_SYSTEM_UID],
            deliveredTo: [ENDEAVOR_SYSTEM_UID],
        });

        const convRef = messagingDb
            .collection("conversations")
            .doc(conversationId);
        batch.update(convRef, {
            lastMessage: text,
            lastMessageAt: FieldValue.serverTimestamp(),
            lastSenderId: ENDEAVOR_SYSTEM_UID,
            [`unreadCounts.${userId}`]: FieldValue.increment(1),
        });

        await batch.commit();
    } catch (err) {
        console.error(
            `[endeavorEvents] Failed to notify user ${userId}:`,
            err
        );
    }
}

async function getOrCreateSystemConversation(
    messagingDb: FirebaseFirestore.Firestore,
    userId: string
): Promise<string> {
    const sorted = [ENDEAVOR_SYSTEM_UID, userId].sort();
    const existing = await messagingDb
        .collection("conversations")
        .where("participantIds", "==", sorted)
        .limit(1)
        .get();

    if (!existing.empty) return existing.docs[0].id;

    const ref = messagingDb.collection("conversations").doc();
    await ref.set({
        participantIds: sorted,
        lastMessage: "",
        lastMessageAt: FieldValue.serverTimestamp(),
        lastSenderId: ENDEAVOR_SYSTEM_UID,
        unreadCounts: { [userId]: 0 },
        createdAt: FieldValue.serverTimestamp(),
    });
    return ref.id;
}
