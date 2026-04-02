import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";

/**
 * Checks and enforces per-user rate limits backed by Firestore.
 *
 * Document path: rateLimits/{uid}/functions/{functionName}
 * Fields:
 *   count      – number of calls in the current window
 *   windowStart – timestamp (epoch ms) when the current window began
 *
 * Uses a Firestore transaction to guarantee atomicity under concurrency.
 *
 * @param uid          Firebase Auth UID of the calling user
 * @param functionName Logical name of the function (used as Firestore doc ID)
 * @param maxCalls     Maximum number of allowed calls within the window
 * @param windowMinutes Length of the sliding window in minutes
 *
 * @throws HttpsError('resource-exhausted') when the limit is exceeded
 */
export async function checkRateLimit(
    uid: string,
    functionName: string,
    maxCalls: number,
    windowMinutes: number
): Promise<void> {
    const db = getFirestore();
    const docRef = db
        .collection("rateLimits")
        .doc(uid)
        .collection("functions")
        .doc(functionName);

    const windowMs = windowMinutes * 60 * 1000;
    const now = Date.now();

    await db.runTransaction(async (tx) => {
        const snap = await tx.get(docRef);

        if (!snap.exists) {
            // First call ever — initialise the window
            tx.set(docRef, {
                count: 1,
                windowStart: now,
            });
            return;
        }

        const data = snap.data()!;
        const windowStart: number =
            typeof data.windowStart === "number"
                ? data.windowStart
                : (data.windowStart as FirebaseFirestore.Timestamp).toMillis();
        const count: number = data.count ?? 0;

        if (now - windowStart >= windowMs) {
            // Window has expired — start a fresh one
            tx.set(docRef, {
                count: 1,
                windowStart: now,
            });
            return;
        }

        // Still within the window — check the limit
        if (count >= maxCalls) {
            const resetInMs = windowMs - (now - windowStart);
            const resetInMinutes = Math.ceil(resetInMs / 60000);
            throw new HttpsError(
                "resource-exhausted",
                `Rate limit exceeded for ${functionName}. ` +
                `You have used ${count}/${maxCalls} calls. ` +
                `Resets in approximately ${resetInMinutes} minute(s).`
            );
        }

        // Increment the counter
        tx.update(docRef, { count: FieldValue.increment(1) });
    });
}
