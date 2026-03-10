import { onCallGenkit, hasClaim } from "firebase-functions/https";
import { defineSecret } from "firebase-functions/params";
import { getFirestore } from "firebase-admin/firestore";
import { googleAI } from "@genkit-ai/google-genai";
import { genkit, z } from "genkit";
import { enableFirebaseTelemetry } from "@genkit-ai/firebase";

enableFirebaseTelemetry();

const googleAIApiKey = defineSecret("GOOGLE_GENAI_API_KEY");

const ai = genkit({
  plugins: [googleAI()],
  model: googleAI.model("gemini-3-flash-preview"),
});

const SearchInputSchema = z.object({
  query: z.string(),
  currentUserId: z.string(),
});

const MatchResultSchema = z.object({
  results: z.array(z.object({
    userId: z.string(),
    score: z.number(),
    reason: z.string(),
  })),
});

const userMatchFlow = ai.defineFlow(
  {
    name: "userMatchFlow",
    inputSchema: SearchInputSchema,
    outputSchema: MatchResultSchema,
  },
  async ({ query, currentUserId }) => {
    console.log("[userMatchFlow] Starting match flow execution for user:", currentUserId);
    const db = getFirestore();
    let snap;
    try {
      console.log("[userMatchFlow] Attempting to fetch users from Firestore...");
      snap = await db.collection("users").get();
      console.log(`[userMatchFlow] Successfully fetched ${snap.size} users.`);
    } catch (error) {
      console.error("[userMatchFlow] ERROR fetching users from Firestore:", error);
      throw error;
    }

    const profiles = snap.docs
      .filter(doc => doc.id !== currentUserId)
      .map(doc => {
        const d = doc.data();
        return {
          id: doc.id,
          firstName: d.firstName ?? "",
          lastName: d.lastName ?? "",
          role: d.role ?? "",
          personalBio: d.personalBio ?? "",
          userType: d.userType ?? "",
          nationality: d.nationality ?? "",
          languages: (d.languages ?? []).join(", "),
        };
      });

    console.log(`[userMatchFlow] Formatted ${profiles.length} profiles for AI matching.`);

    if (profiles.length === 0) {
      console.log("[userMatchFlow] No profiles available to match, returning empty array.");
      return { results: [] };
    }

    console.log("[userMatchFlow] Invoking Gemini model for matching...");
    let output;
    try {
      const result = await ai.generate({
        model: googleAI.model("gemini-3-flash-preview"),
        prompt: `
You are the matching engine for the Endeavor network, a curated global platform
for high-impact entrepreneurs, mentors, and investors.

User request: "${query}"

Available profiles:
${JSON.stringify(profiles, null, 2)}

Analyze each profile and score its compatibility with the user request from 0 to 100.
Consider: role, professional bio, sector, user type, nationality, languages.
Be precise and reasoning-based in your scoring.
        `,
        output: { schema: MatchResultSchema },
        config: { temperature: 0.2 },
      });
      output = result.output;
      console.log("[userMatchFlow] Gemini generation completed.", output);
    } catch (error) {
      console.error("[userMatchFlow] ERROR generating AI matches:", error);
      throw error;
    }

    if (!output) {
      const err = new Error("No output from model");
      console.error(err);
      throw err;
    }

    const matches = output.results
      .filter(r => r.score >= 30)
      .sort((a, b) => b.score - a.score)
      .slice(0, 5);

    console.log(`[userMatchFlow] Returning ${matches.length} filtered matches.`);
    return { results: matches };
  }
);

export const searchUsersWithAI = onCallGenkit(
  {
    secrets: [googleAIApiKey],
    authPolicy: hasClaim("email_verified"),
  },
  userMatchFlow
);
