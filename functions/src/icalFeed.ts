import { onRequest } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

const ICAL_FEED_URL = "https://icalfeed-gpxg3at2wq-ew.a.run.app";

export const icalFeed = onRequest(
    {
        region: "europe-west1",
        cors: false,
    },
    async (req, res) => {
        const token = (req.query.token as string | undefined)?.trim();

        if (!token) {
            res.status(401).send("Unauthorized: missing token");
            return;
        }

        const db = getFirestore();

        // Look up the user whose icalToken matches
        const snap = await db
            .collection("users")
            .where("icalToken", "==", token)
            .limit(1)
            .get();

        if (snap.empty) {
            res.status(401).send("Unauthorized: invalid token");
            return;
        }

        const userDoc = snap.docs[0];
        const data = userDoc.data();

        // Validate expiry
        const expiryRaw = data.icalTokenExpiry as Timestamp | undefined;
        if (!expiryRaw) {
            res.status(401).send("Unauthorized: token has no expiry");
            return;
        }
        const expiryMs = expiryRaw.toMillis();
        if (Date.now() > expiryMs) {
            res.status(401).send("Unauthorized: token expired");
            return;
        }

        // userId is the Firestore document ID (same as UserProfile.id.uuidString)
        const userId = data.id as string;
        if (!userId) {
            res.status(500).send("Internal error: user id missing");
            return;
        }

        // Fetch events for this user
        const eventsSnap = await db
            .collection("events")
            .where("participantIds", "array-contains", userId)
            .get();

        const events = eventsSnap.docs.map(doc => {
            const d = doc.data();
            return {
                id: doc.id,
                title: d.title as string,
                description: (d.description as string) ?? "",
                startDate: (d.startDate as Timestamp).toDate(),
                endDate: (d.endDate as Timestamp).toDate(),
                location: (d.location as string) ?? "",
                status: (d.status as string) ?? "confirmed",
            };
        });

        const ical = generateIcal(events);

        res.setHeader("Content-Type", "text/calendar; charset=utf-8");
        res.setHeader("Content-Disposition", "attachment; filename=endeavor.ics");
        res.setHeader("Cache-Control", "no-cache, no-store");
        res.status(200).send(ical);
    }
);

/**
 * Returns the base URL for building an iCal feed link.
 * Kept here so iOS and the function share the same canonical URL.
 */
export const icalFeedBaseUrl = ICAL_FEED_URL;

// ---------------------------------------------------------------------------
// iCal generation
// ---------------------------------------------------------------------------

function generateIcal(events: {
    id: string;
    title: string;
    description: string;
    startDate: Date;
    endDate: Date;
    location: string;
    status: string;
}[]): string {
    const formatDate = (date: Date): string =>
        date.toISOString().replace(/[-:]/g, "").split(".")[0] + "Z";

    const escapeText = (text: string): string =>
        text.replace(/\\/g, "\\\\").replace(/;/g, "\\;").replace(/,/g, "\\,").replace(/\n/g, "\\n");

    const lines: string[] = [
        "BEGIN:VCALENDAR",
        "VERSION:2.0",
        "PRODID:-//Endeavor//Endeavor Calendar//EN",
        "X-WR-CALNAME:Endeavor",
        "X-WR-TIMEZONE:UTC",
        "CALSCALE:GREGORIAN",
        "METHOD:PUBLISH",
        "REFRESH-INTERVAL;VALUE=DURATION:PT1H",
        "X-WR-CALDESC:Your Endeavor meetings and events",
    ];

    for (const event of events) {
        lines.push(
            "BEGIN:VEVENT",
            `UID:${event.id}@endeavor.org`,
            `DTSTAMP:${formatDate(new Date())}`,
            `DTSTART:${formatDate(event.startDate)}`,
            `DTEND:${formatDate(event.endDate)}`,
            `SUMMARY:${escapeText(event.title)}`,
            `DESCRIPTION:${escapeText(event.description)}`,
            ...(event.location ? [`LOCATION:${escapeText(event.location)}`] : []),
            `STATUS:${event.status === "confirmed" ? "CONFIRMED" : event.status === "cancelled" ? "CANCELLED" : "TENTATIVE"}`,
            "END:VEVENT"
        );
    }

    lines.push("END:VCALENDAR");
    return lines.join("\r\n");
}
