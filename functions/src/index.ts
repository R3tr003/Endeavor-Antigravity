import * as admin from "firebase-admin";

// Initialize firebase-admin (must happen before any other imports that use it)
if (!admin.apps.length) {
    admin.initializeApp();
}

// Export Salesforce Cloud Functions
export {
    checkSalesforceAuthorization,
    getSalesforceContactData,
    checkAndFetchSalesforceContact,
    checkUserExists,
} from "./salesforce";

export { searchUsersWithAI } from "./aiSearch";
export { classifyMessage, recheckConversation } from "./messageFilter";
export { generateMeetLink, cancelCalendarEvent } from "./meetProvider";
export { icalFeed } from "./icalFeed";
export { checkMeetingCompletions } from "./meetingCompleted";
export { saveUserMapping } from "./userMapping";
