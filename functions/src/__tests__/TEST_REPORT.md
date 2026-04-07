# Backend Test Report (Firebase Functions)

> This report is automatically generated every time `npm test` is executed.

**Last Executed**: 4/7/2026, 4:10:46 PM GMT+2

## 📊 Summary
- **Test Suites**: 5 passed, 0 failed, 5 total
- **Tests**: 24 passed, 0 failed, 24 total
- **Execution Time**: 8.71s

## ✅ Passed Test Suites

### meetProvider.test.ts (6 tests passed)
- ✓ *Meet Provider tests > generateMeetLink > throws if no valid arguments are provided*
- ✓ *Meet Provider tests > generateMeetLink > returns forbidden if the user is not a participant*
- ✓ *Meet Provider tests > generateMeetLink > succesfully generates a google meet link*
- ✓ *Meet Provider tests > generateMeetLink > succesfully generates a microsoft teams link*
- ✓ *Meet Provider tests > cancelCalendarEvent > returns success if event is not found*
- ✓ *Meet Provider tests > cancelCalendarEvent > deletes google event successfully*

### salesforce.test.ts (10 tests passed)
- ✓ *Salesforce Functions > checkUserExists > throws invalid-argument error if email is missing*
- ✓ *Salesforce Functions > checkUserExists > returns { exists: false } if the user document is not found*
- ✓ *Salesforce Functions > checkUserExists > returns { exists: true } and the correct userId when user and company are found*
- ✓ *Salesforce Functions > checkSalesforceAuthorization > throws if email missing*
- ✓ *Salesforce Functions > checkSalesforceAuthorization > returns authorized: false when SOQL returns zero records*
- ✓ *Salesforce Functions > checkSalesforceAuthorization > returns authorized: true and contactId when SOQL finds a record*
- ✓ *Salesforce Functions > getSalesforceContactData > throws if contactId missing*
- ✓ *Salesforce Functions > getSalesforceContactData > parses languages correctly and maps fields*
- ✓ *Salesforce Functions > checkAndFetchSalesforceContact > throws if email missing*
- ✓ *Salesforce Functions > checkAndFetchSalesforceContact > functions correctly combining authorization and data pulling*

### icalFeed.test.ts (4 tests passed)
- ✓ *iCal Feed Function > returns 401 if token is missing*
- ✓ *iCal Feed Function > returns 401 if token is invalid*
- ✓ *iCal Feed Function > returns 401 if token is expired*
- ✓ *iCal Feed Function > generates an iCal feed with events for a valid token*

### messageFilter.test.ts (2 tests passed)
- ✓ *Message Filter: recheckConversation > throws unauthenticated if no auth is provided*
- ✓ *Message Filter: recheckConversation > verifies permission mapping and identifies spam conversation successfully*

### aiSearch.test.ts (2 tests passed)
- ✓ *AI Search Function > returns empty results if no other users are found*
- ✓ *AI Search Function > returns GenAI filtered matches when other users exist*

---

## 🚀 Instructions to Run Tests

The backend environment uses **Jest** alongside **firebase-functions-test** to mock the cloud environment.

To run these tests locally and automatically update this report without any side effects on the production database, execute:

```bash
cd "Endeavor Antigravity/functions"
npm install
npm test
```

To run a specific test suite file:
```bash
npx jest src/__tests__/aiSearch.test.ts
```
