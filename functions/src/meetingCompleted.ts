import * as functions from "firebase-functions/v2";
import * as admin from "firebase-admin";

const db = admin.firestore();

interface MeetingEvent {
    id: string;
    status: string;
    startDate: admin.firestore.Timestamp;
    endDate: admin.firestore.Timestamp;
    meetProvider: string;
    participantIds: string[];
    completionNotifiedAt?: admin.firestore.Timestamp;
}

/**
 * Scheduled Cloud Function (every 6 hours) that detects confirmed meetings
 * whose start time has passed and writes a `meeting_completed` marker document.
 *
 * NOTE: Firebase Admin SDK does not support logEvent() directly for Analytics.
 * Instead, this function writes a Firestore document to `analytics_triggers/{eventId}`.
 * The iOS app reads these triggers on CalendarView open and logs the event
 * client-side using AnalyticsService.shared.logMeetingCompleted() — this ensures
 * the event is attributed to the correct Firebase Analytics user_id.
 *
 * This avoids needing to store firebase_app_instance_id per user,
 * and is more reliable than the Measurement Protocol for conversion attribution.
 */
export const checkMeetingCompletions = functions.scheduler.onSchedule(
    {
        schedule: "every 6 hours",
        region: "europe-west1",
        timeoutSeconds: 120,
    },
    async (_event) => {
        const now = admin.firestore.Timestamp.now();
        // Look for events that started more than 1 hour ago (buffer time for the meeting to finish)
        const cutoffTime = admin.firestore.Timestamp.fromMillis(
            now.toMillis() - 60 * 60 * 1000
        );

        const snapshot = await db
            .collection("events")
            .where("status", "==", "confirmed")
            .where("startDate", "<=", cutoffTime)
            .get();

        if (snapshot.empty) {
            console.log("[meetingCompleted] No meetings to process.");
            return;
        }

        const batch = db.batch();
        let count = 0;

        for (const doc of snapshot.docs) {
            const event = { id: doc.id, ...doc.data() } as MeetingEvent;

            // Skip if already notified
            if (event.completionNotifiedAt) continue;

            // Calculate duration from Firestore timestamps
            const durationMs =
                event.endDate.toMillis() - event.startDate.toMillis();
            const durationMinutes = Math.round(durationMs / 60000);

            // Write a trigger document for each participant — the app will pick this up
            // on the next CalendarView open and log meeting_completed client-side.
            for (const userId of event.participantIds) {
                const triggerRef = db
                    .collection("analytics_triggers")
                    .doc(`meeting_completed_${event.id}_${userId}`);
                batch.set(triggerRef, {
                    eventType: "meeting_completed",
                    userId,
                    eventId: event.id,
                    provider: event.meetProvider ?? "none",
                    durationMinutes,
                    createdAt: now,
                    consumed: false,
                });
            }

            // Mark the event so this function never processes it again
            batch.update(doc.ref, {
                completionNotifiedAt: now,
            });

            count++;
        }

        await batch.commit();
        console.log(
            `[meetingCompleted] Created triggers for ${count} completed meeting(s).`
        );
    }
);
