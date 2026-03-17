import { onCall } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";
import { google } from "googleapis";

export const generateMeetLink = onCall(
  { region: "europe-west1" },
  async (request) => {
    if (!request.auth) throw new Error("Unauthenticated");

    const { eventId, provider, userId } = request.data as {
      eventId: string;
      provider: "google_meet" | "microsoft_teams" | "none";
      userId: string;
    };

    if (!eventId || !provider || !userId) throw new Error("Missing params");

    const db = getFirestore();
    const eventRef = db.collection("events").doc(eventId);
    const eventSnap = await eventRef.get();
    if (!eventSnap.exists) throw new Error("Event not found");

    const eventData = eventSnap.data()!;

    // Verifica che il richiedente (UUID) sia partecipante dell'evento
    if (!eventData.participantIds.includes(userId)) {
      throw new Error("Forbidden");
    }

    let meetLink = "";

    switch (provider) {
      case "google_meet": {
        // Crea uno Space persistente tramite Google Meet REST API
        const auth = new google.auth.GoogleAuth({
          scopes: ["https://www.googleapis.com/auth/meetings.space.created"],
        });
        const authClient = await auth.getClient();
        const res = await (authClient as any).request({
          url: "https://meet.googleapis.com/v1/spaces",
          method: "POST",
          data: {},
        });
        meetLink = (res.data as { meetingUri?: string }).meetingUri ?? "";
        break;
      }

      case "microsoft_teams":
        // Deep link Teams per creare un meeting instant
        meetLink = "https://teams.microsoft.com/l/meeting/new";
        break;

      case "none":
        meetLink = "";
        break;
    }

    // Salva il link sull'evento
    await eventRef.update({ meetLink });

    return { meetLink };
  }
);
