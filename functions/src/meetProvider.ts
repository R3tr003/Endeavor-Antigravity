import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";
import { checkRateLimit } from "./rateLimiter";

export const generateMeetLink = onCall(
  { region: "europe-west1" },
  async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Unauthenticated");

    // Rate limit: 30 calls per hour per user
    await checkRateLimit(request.auth.uid, "generateMeetLink", 30, 60);

    const { eventId, provider, userId, googleAccessToken, microsoftAccessToken } = request.data as {
      eventId: string;
      provider: "google_meet" | "microsoft_teams" | "none";
      userId: string;
      googleAccessToken?: string;
      microsoftAccessToken?: string;
    };

    if (!eventId || !provider || !userId) throw new Error("Missing params");

    const db = getFirestore();
    const eventRef = db.collection("events").doc(eventId);
    const eventSnap = await eventRef.get();
    if (!eventSnap.exists) throw new Error("Event not found");

    const eventData = eventSnap.data()!;
    if (!eventData.participantIds.includes(userId)) throw new Error("Forbidden");

    let meetLink = "";

    switch (provider) {
      case "google_meet": {
        // Richiede il token OAuth2 dell'utente Google
        if (!googleAccessToken) {
          throw new Error("Google access token required for Google Meet");
        }

        // Crea un evento Google Calendar con conferenceData — genera automaticamente un Meet link persistente
        const startDate = (eventData.startDate as FirebaseFirestore.Timestamp).toDate();
        const endDate = (eventData.endDate as FirebaseFirestore.Timestamp).toDate();

        const calendarResponse = await fetch(
          "https://www.googleapis.com/calendar/v3/calendars/primary/events?conferenceDataVersion=1",
          {
            method: "POST",
            headers: {
              "Authorization": `Bearer ${googleAccessToken}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              summary: eventData.title as string,
              description: (eventData.description as string) || "",
              start: {
                dateTime: startDate.toISOString(),
                timeZone: "UTC",
              },
              end: {
                dateTime: endDate.toISOString(),
                timeZone: "UTC",
              },
              conferenceData: {
                createRequest: {
                  requestId: eventId,  // usa eventId come requestId per idempotenza
                  conferenceSolutionKey: {
                    type: "hangoutsMeet",
                  },
                },
              },
            }),
          }
        );

        if (!calendarResponse.ok) {
          const errorBody = await calendarResponse.text();
          console.error("[generateMeetLink] Calendar API error:", errorBody);
          throw new Error(`Calendar API failed: ${calendarResponse.status}`);
        }

        const calendarEvent = await calendarResponse.json() as {
          id?: string;
          conferenceData?: {
            entryPoints?: Array<{ entryPointType: string; uri: string }>;
          };
        };

        // Estrai il Meet link dalla risposta
        const meetEntry = calendarEvent.conferenceData?.entryPoints?.find(
          (e) => e.entryPointType === "video"
        );
        meetLink = meetEntry?.uri ?? "";

        if (!meetLink) {
          throw new Error("Meet link not found in Calendar API response");
        }

        // Salva l'ID evento Google Calendar per poter cancellarlo in seguito
        const googleCalendarEventId = calendarEvent.id ?? "";
        await eventRef.update({ meetLink, googleCalendarEventId });

        console.log(`[generateMeetLink] Meet link generated for event ${eventId}: ${meetLink}`);
        break;
      }

      case "microsoft_teams": {
        if (!microsoftAccessToken) {
          throw new Error("Microsoft access token required for Teams");
        }

        const startDate = (eventData.startDate as FirebaseFirestore.Timestamp).toDate();
        const endDate = (eventData.endDate as FirebaseFirestore.Timestamp).toDate();

        const teamsResponse = await fetch(
          "https://graph.microsoft.com/v1.0/me/onlineMeetings",
          {
            method: "POST",
            headers: {
              "Authorization": `Bearer ${microsoftAccessToken}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              subject: eventData.title as string,
              startDateTime: startDate.toISOString(),
              endDateTime: endDate.toISOString(),
            }),
          }
        );

        if (!teamsResponse.ok) {
          const errorBody = await teamsResponse.text();
          console.error("[generateMeetLink] Teams Graph API error:", errorBody);
          throw new Error(`Teams API failed: ${teamsResponse.status}`);
        }

        const teamsEvent = await teamsResponse.json() as {
          joinWebUrl?: string;
        };

        meetLink = teamsEvent.joinWebUrl ?? "";

        if (!meetLink) {
          throw new Error("Teams join URL not found in Graph API response");
        }

        console.log(`[generateMeetLink] Teams link generated for event ${eventId}: ${meetLink}`);
        break;
      }

      case "none":
        meetLink = "";
        break;
    }

    // Per Google Meet: link e calendarEventId già salvati nel case sopra.
    // Per Teams: salva solo il link (Teams non supporta cancellazione via Graph nelle stesse condizioni).
    if (provider !== "google_meet") {
      await eventRef.update({ meetLink });
    }

    return { meetLink };
  }
);

export const cancelCalendarEvent = onCall(
  { region: "europe-west1" },
  async (request) => {
    if (!request.auth) throw new Error("Unauthenticated");

    const { eventId, googleAccessToken } = request.data as {
      eventId: string;
      googleAccessToken: string;
    };

    if (!eventId || !googleAccessToken) throw new Error("Missing params");

    const db = getFirestore();
    const eventRef = db.collection("events").doc(eventId);
    const eventSnap = await eventRef.get();
    if (!eventSnap.exists) return { success: true }; // event already gone, nothing to do

    const googleCalendarEventId = eventSnap.data()?.googleCalendarEventId as string | undefined;
    if (!googleCalendarEventId) {
      return { success: true }; // no calendar event was created, nothing to delete
    }

    const deleteResponse = await fetch(
      `https://www.googleapis.com/calendar/v3/calendars/primary/events/${googleCalendarEventId}`,
      {
        method: "DELETE",
        headers: { "Authorization": `Bearer ${googleAccessToken}` },
      }
    );

    // 204 = deleted, 404/410 = already gone — all are acceptable
    if (!deleteResponse.ok && deleteResponse.status !== 404 && deleteResponse.status !== 410) {
      const errorBody = await deleteResponse.text();
      console.error("[cancelCalendarEvent] Calendar API error:", errorBody);
      throw new Error(`Calendar API failed: ${deleteResponse.status}`);
    }

    await eventRef.update({ googleCalendarEventId: null });
    console.log(`[cancelCalendarEvent] Calendar event ${googleCalendarEventId} deleted for event ${eventId}`);
    return { success: true };
  }
);
