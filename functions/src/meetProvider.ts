import { onCall } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

export const generateMeetLink = onCall(
  { region: "europe-west1" },
  async (request) => {
    if (!request.auth) throw new Error("Unauthenticated");

    const { eventId, provider } = request.data as {
      eventId: string;
      provider: "google_meet" | "microsoft_teams" | "none";
    };

    if (!eventId || !provider) throw new Error("Missing params");

    const db = getFirestore();
    const eventRef = db.collection("events").doc(eventId);
    const eventSnap = await eventRef.get();
    if (!eventSnap.exists) throw new Error("Event not found");

    const eventData = eventSnap.data()!;

    // Verifica che il richiedente sia partecipante
    if (!eventData.participantIds.includes(request.auth.uid)) {
      throw new Error("Forbidden");
    }

    let meetLink = "";

    switch (provider) {
      case "google_meet":
        // meet.new crea istantaneamente un meeting Google Meet
        meetLink = "https://meet.new";
        break;

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
