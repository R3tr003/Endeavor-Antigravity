import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

export const saveUserMapping = onCall(
    { region: "europe-west1" },
    async (request) => {
        if (!request.auth) {
            throw new HttpsError("unauthenticated", "Authentication required.");
        }

        const { firebaseUid, uuid } = request.data as { firebaseUid: string; uuid: string };

        if (!firebaseUid || !uuid) {
            throw new HttpsError("invalid-argument", "firebaseUid and uuid are required.");
        }

        // Only allow a user to write their own mapping.
        if (request.auth.uid !== firebaseUid) {
            throw new HttpsError("permission-denied", "Cannot write mapping for another user.");
        }

        const mapping = { uuid };
        const defaultDb = getFirestore();
        const messagingDb = getFirestore("messaging");

        await Promise.all([
            defaultDb.collection("userMappings").doc(firebaseUid).set(mapping),
            messagingDb.collection("userMappings").doc(firebaseUid).set(mapping),
        ]);

        return { success: true };
    }
);
