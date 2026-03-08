import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { setGlobalOptions } from "firebase-functions/v2";
import { logger } from "firebase-functions/v2";
import fetch from "node-fetch";

setGlobalOptions({ region: "europe-west1" });

// Ensure firebase-admin is initialized (idempotent)
if (!admin.apps.length) {
    admin.initializeApp();
}

const SALESFORCE_BASE_URL =
    "https://orgfarm-54acd29e9a-dev-ed.develop.my.salesforce.com";

// ---------------------------------------------------------------------------
// Helper: Obtain Salesforce access token via Client Credentials Flow
// ---------------------------------------------------------------------------
async function getSalesforceAccessToken(): Promise<string> {
    const clientId = process.env.SALESFORCE_CLIENT_ID;
    const clientSecret = process.env.SALESFORCE_CLIENT_SECRET;

    if (!clientId || !clientSecret) {
        throw new HttpsError("internal", "Salesforce credentials not configured.");
    }

    const params = new URLSearchParams({
        grant_type: "client_credentials",
        client_id: clientId,
        client_secret: clientSecret,
    });

    const response = await fetch(
        `${SALESFORCE_BASE_URL}/services/oauth2/token`,
        {
            method: "POST",
            headers: { "Content-Type": "application/x-www-form-urlencoded" },
            body: params.toString(),
        }
    );

    if (!response.ok) {
        const body = await response.text();
        logger.error("Salesforce OAuth failed", { status: response.status, body });
        throw new HttpsError("unavailable", "Failed to authenticate with Salesforce.");
    }

    const data = (await response.json()) as {
        access_token?: string;
        token_type?: string;
        scope?: string;
        instance_url?: string;
    };
    logger.info("Salesforce OAuth token received", {
        hasToken: !!data.access_token,
        tokenType: data.token_type,
        scope: data.scope,
        instance_url: data.instance_url,
    });
    if (!data.access_token) {
        throw new HttpsError("internal", "No access token returned by Salesforce.");
    }
    return data.access_token;
}

// ---------------------------------------------------------------------------
// Helper: Run a SOQL query against Salesforce
// ---------------------------------------------------------------------------
async function soqlQuery(
    accessToken: string,
    query: string
): Promise<{ records: Record<string, unknown>[] }> {
    const url = `${SALESFORCE_BASE_URL}/services/data/v60.0/query?q=${encodeURIComponent(query)}`;
    const response = await fetch(url, {
        headers: { Authorization: `Bearer ${accessToken}` },
    });

    if (!response.ok) {
        const body = await response.text();
        logger.error("SOQL query failed", { status: response.status, body });
        throw new HttpsError("internal", "Salesforce query failed.");
    }

    return (await response.json()) as { records: Record<string, unknown>[] };
}

// ---------------------------------------------------------------------------
// Helper: Parse languages string
// ---------------------------------------------------------------------------
function parseLanguages(raw: string): string[] {
    if (!raw) return [];
    return raw.split(";").map(l => l.trim()).filter(l => l.length > 0);
}

// ---------------------------------------------------------------------------
// Cloud Function 1: checkSalesforceAuthorization
// ---------------------------------------------------------------------------
export const checkSalesforceAuthorization = onCall(
    {
        timeoutSeconds: 15,
        secrets: ["SALESFORCE_CLIENT_ID", "SALESFORCE_CLIENT_SECRET"],
    },
    async (request) => {
        const email = ((request.data.email as string) || "").trim().toLowerCase();
        if (!email) {
            throw new HttpsError("invalid-argument", "Email is required.");
        }

        logger.info("checkSalesforceAuthorization called", { email });

        const accessToken = await getSalesforceAccessToken();

        const soql = `SELECT Id, Email FROM Contact WHERE Email = '${email.replace(/'/g, "\\'")}' LIMIT 1`;
        const result = await soqlQuery(accessToken, soql);

        if (result.records.length === 0) {
            logger.info("Contact not found in Salesforce", { email });
            return { authorized: false };
        }

        const contactId = result.records[0]["Id"] as string;
        logger.info("Contact authorized", { email, contactId });
        return { authorized: true, contactId };
    }
);

// ---------------------------------------------------------------------------
// Cloud Function 2: getSalesforceContactData
// ---------------------------------------------------------------------------
export const getSalesforceContactData = onCall(
    {
        timeoutSeconds: 15,
        secrets: ["SALESFORCE_CLIENT_ID", "SALESFORCE_CLIENT_SECRET"],
    },
    async (request) => {
        const contactId = ((request.data.contactId as string) || "").trim();
        if (!contactId) {
            throw new HttpsError("invalid-argument", "contactId is required.");
        }

        logger.info("getSalesforceContactData called", { contactId });

        const accessToken = await getSalesforceAccessToken();

        const soql = `
      SELECT Id, FirstName, LastName, Email,
             Title, Description,
             Nationality__c, Language_Capabilities__c, Platform_User_Profile__c,
             Phone, MobilePhone,
             AccountId, Account.Name, Account.Website, Account.BillingCountry,
             Account.BillingCity, Account.Description, Account.Vertical__c,
             Account.Endeavor_Chapter__c
      FROM Contact
      WHERE Id = '${contactId.replace(/'/g, "\\'")}'
      LIMIT 1
    `;
        const result = await soqlQuery(accessToken, soql);

        if (result.records.length === 0) {
            throw new HttpsError("not-found", "Contact not found in Salesforce.");
        }

        const c = result.records[0];
        const account = (c["Account"] as Record<string, unknown>) || {};

        return {
            // Contact → UserProfile
            firstName: (c["FirstName"] as string) || "",
            lastName: (c["LastName"] as string) || "",
            jobTitle: (c["Title"] as string) || "",
            bio: (c["Description"] as string) || "",
            nationality: (c["Nationality__c"] as string) || "",
            languages: parseLanguages(c["Language_Capabilities__c"] as string || ""),
            phone: (c["MobilePhone"] as string) || (c["Phone"] as string) || "",
            userType: (c["Platform_User_Profile__c"] as string) || "",
            // Account → CompanyProfile
            companyName: (account["Name"] as string) || "",
            companyWebsite: (account["Website"] as string) || "",
            companyCountry: (account["BillingCountry"] as string) || "",
            companyCity: (account["BillingCity"] as string) || "",
            companyBio: (account["Description"] as string) || "",
            companyVertical: (account["Vertical__c"] as string) || "",
            companyChapter: (account["Endeavor_Chapter__c"] as string) || "",
        };
    }
);

// ---------------------------------------------------------------------------
// Cloud Function 3: checkAndFetchSalesforceContact
// ---------------------------------------------------------------------------
export const checkAndFetchSalesforceContact = onCall(
    {
        timeoutSeconds: 20,
        secrets: ["SALESFORCE_CLIENT_ID", "SALESFORCE_CLIENT_SECRET"],
    },
    async (request) => {
        const email = ((request.data.email as string) || "").trim().toLowerCase();
        if (!email) throw new HttpsError("invalid-argument", "Email is required.");

        logger.info("checkAndFetchSalesforceContact called", { email });

        const accessToken = await getSalesforceAccessToken();

        const soql = `
            SELECT Id, FirstName, LastName, Email,
                   Title, Description,
                   Nationality__c, Language_Capabilities__c, Platform_User_Profile__c,
                   Phone, MobilePhone,
                   AccountId, Account.Name, Account.Website, Account.BillingCountry,
                   Account.BillingCity, Account.Description, Account.Vertical__c,
                   Account.Endeavor_Chapter__c
            FROM Contact
            WHERE Email = '${email.replace(/'/g, "\\'")}'
            LIMIT 1
        `;
        const result = await soqlQuery(accessToken, soql);

        if (result.records.length === 0) {
            logger.info("Contact not found in Salesforce", { email });
            return { authorized: false };
        }

        const c = result.records[0];
        const account = (c["Account"] as Record<string, unknown>) || {};
        const contactId = c["Id"] as string;

        logger.info("Contact authorized and fetched", { email, contactId });

        return {
            authorized: true,
            contactId,
            firstName: (c["FirstName"] as string) || "",
            lastName: (c["LastName"] as string) || "",
            jobTitle: (c["Title"] as string) || "",
            bio: (c["Description"] as string) || "",
            nationality: (c["Nationality__c"] as string) || "",
            languages: parseLanguages(c["Language_Capabilities__c"] as string || ""),
            phone: (c["MobilePhone"] as string) || (c["Phone"] as string) || "",
            userType: (c["Platform_User_Profile__c"] as string) || "",
            companyName: (account["Name"] as string) || "",
            companyWebsite: (account["Website"] as string) || "",
            companyCountry: (account["BillingCountry"] as string) || "",
            companyCity: (account["BillingCity"] as string) || "",
            companyBio: (account["Description"] as string) || "",
            companyVertical: (account["Vertical__c"] as string) || "",
            companyChapter: (account["Endeavor_Chapter__c"] as string) || "",
        };
    }
);

// ---------------------------------------------------------------------------
// Cloud Function 4: checkUserExists
// Checks if a user document exists in Firestore for the given email.
// Uses admin SDK — bypasses client-side auth rules.
// ---------------------------------------------------------------------------
export const checkUserExists = onCall(
    {
        timeoutSeconds: 10,
    },
    async (request) => {
        const email = ((request.data.email as string) || "").trim().toLowerCase();
        if (!email) {
            throw new HttpsError("invalid-argument", "Email is required.");
        }

        logger.info("checkUserExists called", { email });

        const db = admin.firestore();
        const usersSnapshot = await db
            .collection("users")
            .where("email", "==", email)
            .get();

        if (usersSnapshot.empty) {
            logger.info("checkUserExists result", { email, exists: false });
            return { exists: false };
        }

        // Find the user doc that has a linked company (the "complete" profile).
        // If there are duplicates, the one with a company is the correct one.
        for (const userDoc of usersSnapshot.docs) {
            const userId = userDoc.data()["id"] as string;
            if (!userId) continue;

            const companySnapshot = await db
                .collection("companies")
                .where("userId", "==", userId)
                .limit(1)
                .get();

            if (!companySnapshot.empty) {
                logger.info("checkUserExists result — complete profile found", { email, userId, exists: true });
                return { exists: true, userId };
            }
        }

        // User docs exist but none have a company — still "exists" but incomplete
        const firstUserId = usersSnapshot.docs[0].data()["id"] as string || "";
        logger.info("checkUserExists result — user exists but no company", { email, userId: firstUserId, exists: true });
        return { exists: true, userId: firstUserId };
    }
);
