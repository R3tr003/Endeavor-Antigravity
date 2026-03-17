import { onRequest } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";

export const icalFeed = onRequest(
    {
        region: "europe-west1",
        cors: false,
    },
    async (req, res) => {
        const userId = req.query.userId as string;
        const token = req.query.token as string;

        if (!userId || !token) {
            res.status(401).send("Unauthorized");
            return;
        }

        try {
            const decoded = await getAuth().verifyIdToken(token);
            if (decoded.uid !== userId && !(await isAdminUser(decoded.uid))) {
                res.status(403).send("Forbidden");
                return;
            }
        } catch {
            res.status(401).send("Invalid token");
            return;
        }

        const db = getFirestore();
        const snap = await db.collection("events")
            .where("participantIds", "array-contains", userId)
            .get();

        const events = snap.docs.map(doc => {
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

function generateIcal(events: { id: string; title: string; description: string; startDate: Date; endDate: Date; location: string; status: string }[]): string {
    const formatDate = (date: Date): string => {
        return date.toISOString().replace(/[-:]/g, "").split(".")[0] + "Z";
    };

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

async function isAdminUser(uid: string): Promise<boolean> {
    try {
        const user = await getAuth().getUser(uid);
        return (user.customClaims as Record<string, unknown>)?.admin === true;
    } catch { return false; }
}
