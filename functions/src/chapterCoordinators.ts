import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

/**
 * Triggered when a meeting event's status changes to "confirmed".
 *
 * For each participant whose company belongs to an Endeavor Chapter:
 * - Finds the Staff coordinator registered for that chapter.
 * - Gets or creates a direct conversation between the participant and the coordinator.
 * - Sends a meeting_invite message so the coordinator sees the meeting card with a "Join" button.
 * - Adds the coordinator to the event's participantIds so the meeting appears on their calendar.
 *
 * All coordinator lookups are silent-fail: if a coordinator is not registered in the app,
 * or if any step fails, the error is logged and skipped — no exception is thrown.
 */
export const notifyChapterCoordinators = onDocumentUpdated(
    {
        document: "events/{eventId}",
        region: "europe-west1",
    },
    async (event) => {
        if (!event.data) return;
        const before = event.data.before.data();
        const after = event.data.after.data();

        // Only fire on the transition pending → confirmed
        if (before.status === "confirmed" || after.status !== "confirmed") return;

        // Idempotency: skip if already processed (e.g. re-trigger from participantIds update)
        if (after.chapterCoordinatorsNotified === true) return;

        const eventId = event.params.eventId;
        const defaultDb = getFirestore();
        const messagingDb = getFirestore("messaging");

        const participantIds: string[] = after.participantIds ?? [];
        const eventTitle: string = after.title ?? "";

        // Map staffUserId → participantId (who "owns" that chapter notification)
        // Using a Map deduplicates coordinators when both participants share the same chapter.
        const staffToNotify = new Map<string, string>();

        for (const participantId of participantIds) {
            try {
                // 1. Find this participant's company
                const companySnap = await defaultDb
                    .collection("companies")
                    .where("userId", "==", participantId)
                    .limit(1)
                    .get();

                if (companySnap.empty) continue;

                const chapter = companySnap.docs[0].data().endeavorChapter as string | undefined;
                if (!chapter) continue;

                // 2. Find the Staff coordinator for this chapter by scanning companies with
                //    the same endeavorChapter and checking the associated user's userType.
                const chapterCompanies = await defaultDb
                    .collection("companies")
                    .where("endeavorChapter", "==", chapter)
                    .get();

                let staffUserId: string | null = null;

                for (const compDoc of chapterCompanies.docs) {
                    const compUserId = compDoc.data().userId as string | undefined;
                    if (!compUserId) continue;
                    // Skip participants already in the meeting
                    if (participantIds.includes(compUserId)) continue;
                    // Skip if already queued
                    if (staffToNotify.has(compUserId)) continue;

                    const userDoc = await defaultDb.collection("users").doc(compUserId).get();
                    if (!userDoc.exists) continue;

                    if (userDoc.data()?.userType === "Staff") {
                        staffUserId = compUserId;
                        break;
                    }
                }

                if (!staffUserId) continue;
                if (staffToNotify.has(staffUserId)) continue;

                staffToNotify.set(staffUserId, participantId);
            } catch (err) {
                console.error(
                    `[notifyChapterCoordinators] Error resolving coordinator for participant ${participantId}:`,
                    err
                );
                // Silent fail — continue with remaining participants
            }
        }

        // Mark as processed regardless of outcome, and add new staff to event participants.
        const newStaffIds = Array.from(staffToNotify.keys());
        const eventUpdate: Record<string, unknown> = { chapterCoordinatorsNotified: true };
        if (newStaffIds.length > 0) {
            eventUpdate["participantIds"] = FieldValue.arrayUnion(...newStaffIds);
        }
        await event.data!.after.ref.update(eventUpdate);

        if (staffToNotify.size === 0) {
            console.log(`[notifyChapterCoordinators] No coordinators found for event ${eventId}.`);
            return;
        }

        // Notify each coordinator via chat
        for (const [staffUserId, participantId] of staffToNotify.entries()) {
            try {
                const convId = await getOrCreateStaffConversation(
                    messagingDb,
                    participantId,
                    staffUserId
                );
                await sendStaffMeetingNotification(
                    messagingDb,
                    convId,
                    participantId,
                    staffUserId,
                    eventId,
                    eventTitle
                );
                console.log(
                    `[notifyChapterCoordinators] Notified coordinator ${staffUserId} for event ${eventId}.`
                );
            } catch (err) {
                console.error(
                    `[notifyChapterCoordinators] Error notifying coordinator ${staffUserId}:`,
                    err
                );
                // Silent fail — continue with remaining coordinators
            }
        }
    }
);

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

async function getOrCreateStaffConversation(
    messagingDb: FirebaseFirestore.Firestore,
    participantId: string,
    staffUserId: string
): Promise<string> {
    // Look for an existing conversation that contains both users
    const snap = await messagingDb
        .collection("conversations")
        .where("participantIds", "array-contains", participantId)
        .get();

    const existing = snap.docs.find((doc) => {
        const ids = doc.data().participantIds as string[];
        return ids.includes(staffUserId);
    });

    if (existing) return existing.id;

    // Create a new conversation — no ban check, staff are always reachable
    const ref = messagingDb.collection("conversations").doc();
    await ref.set({
        participantIds: [participantId, staffUserId],
        lastMessage: "",
        lastMessageAt: FieldValue.serverTimestamp(),
        lastSenderId: "",
        unreadCounts: { [participantId]: 0, [staffUserId]: 0 },
        pinnedBy: [],
        isFiltered: false,
        filterReason: "",
        filterCheckedAt: null,
    });

    return ref.id;
}

async function sendStaffMeetingNotification(
    messagingDb: FirebaseFirestore.Firestore,
    conversationId: string,
    senderId: string,
    staffUserId: string,
    eventId: string,
    eventTitle: string
): Promise<void> {
    const batch = messagingDb.batch();

    const messageRef = messagingDb
        .collection("conversations")
        .doc(conversationId)
        .collection("messages")
        .doc();

    batch.set(messageRef, {
        senderId,
        text: `📹 Meeting invite: ${eventTitle}`,
        createdAt: FieldValue.serverTimestamp(),
        readBy: [senderId],
        deliveredTo: [],
        messageType: "meeting_invite",
        meetingEventId: eventId,
        isSystemMessage: false,
    });

    const conversationRef = messagingDb
        .collection("conversations")
        .doc(conversationId);

    batch.update(conversationRef, {
        lastMessage: `📹 Meeting invite: ${eventTitle}`,
        lastMessageAt: FieldValue.serverTimestamp(),
        lastSenderId: senderId,
        [`unreadCounts.${staffUserId}`]: FieldValue.increment(1),
        lastMessageDeliveredTo: [],
        lastMessageReadBy: [senderId],
    });

    await batch.commit();
}
