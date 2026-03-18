# Endeavor iOS App

Endeavor is a production iOS application for **Endeavor**, a global nonprofit supporting high-impact entrepreneurs. The app connects entrepreneurs with mentors and investors through AI-powered discovery, real-time messaging, and collaborative meeting scheduling — with a curated invite-only access model gated through Salesforce CRM.

---

## Features

- **Invite-only Access via Salesforce** — new users are authorized against a Salesforce CRM before any account is created
- **Deferred Firebase Account Creation** — Firebase Auth accounts are created only after full onboarding is completed, preventing orphan accounts
- **Google Sign-In & Email/Password Auth** — full support for both flows with Salesforce-backed authorization
- **Salesforce Prefill** — onboarding forms are pre-populated from the user's Salesforce Contact record
- **Real-time Messaging** — full chat between users with media sharing (images, documents), delivery receipts (sent/delivered/read), message pinning, and swipe-to-ban
- **AI Message Filtering** — Gemini-powered spam/safety filter runs on every incoming message via Firestore trigger; flagged messages go to a separate "Filtered" inbox
- **Meeting Scheduling** — schedule meetings directly in chat, with Google Meet or Microsoft Teams link generation (via OAuth)
- **Calendar** — full calendar view with event management, iCal subscription feed for native calendar integration
- **AI Mentor Discovery** — Genkit + Gemini-powered natural language search across all users
- **Multi-language** — full localization in English, Spanish, Italian, French, and Brazilian Portuguese
- **Firebase App Check** — AppAttest in production for integrity verification
- **Firebase Performance Monitoring** — custom traces for auth check, conversation load, message load, profile fetch
- **Offline Persistence** — Firestore offline persistence enabled on both databases

---

## Authentication & Onboarding Flow

### New Users (Email/Password)
1. User enters email + password on the Welcome screen
2. App checks Salesforce via Cloud Function (`checkAndFetchSalesforceContact`)
3. If **authorized**: credentials are held in pending state — no Firebase account is created yet
4. User completes the 5-step onboarding (Salesforce-prefilled)
5. On `completeOnboarding()`: Firebase account is created, then user + company profiles are saved to Firestore

### New Users (Google Sign-In)
1. User taps "Continue with Google"
2. App checks Firestore for an existing profile — if none, proceeds to Salesforce check
3. If **authorized**: Google tokens + profile data (name, photo) are stored in pending state
4. User sees Google name and photo pre-loaded in onboarding steps
5. On `completeOnboarding()`: Google Sign-In is finalized with Firebase, then Firestore is saved

### Returning Users
- Email: direct sign-in → Firestore profile loaded → main app
- Google: Firestore check confirms existing profile → Google Sign-In → main app
- **Salesforce is never called for returning users** (fast path)

---

## Architecture

The app follows a strict **MVVM + Repository** pattern:

```
Views         — SwiftUI only, zero business logic, zero Firebase imports
ViewModels    — @Published state, calls Repository methods, @ObservableObject
Repositories  — all Firebase/network calls, always behind a Protocol
Models        — pure Swift structs, Codable, Equatable, Identifiable
```

Every repository is behind a protocol, enabling full mock injection for unit tests. Adding any method requires updating three files in sync: the Protocol, the Firebase implementation, and the Mock.

**Navigation:** `.sheet()` + `@State private var showX: Bool` throughout — no `NavigationLink` usage.

---

## Project Structure

```
app/EndeavorApp/
├── App.swift                              # App entry point, URL handling (Google/MSAL), routing
│
├── Models/
│   ├── Message.swift                      # Chat message (text, image, document, meeting invite)
│   ├── Conversation.swift                 # Conversation with unread counts, pin state, filter state
│   ├── UserProfile.swift                  # UserProfile + CompanyProfile structs
│   ├── CalendarEvent.swift                # Meeting/event with MeetProvider enum (Google Meet, Teams)
│   ├── AppError.swift                     # Single source of all app errors (localized)
│   └── LocationData.swift                 # Country/timezone data
│
├── Repositories/
│   ├── Protocols/
│   │   ├── MessagesRepositoryProtocol.swift
│   │   ├── CalendarRepositoryProtocol.swift
│   │   ├── UserRepositoryProtocol.swift
│   │   ├── NetworkRepositoryProtocol.swift
│   │   ├── AuthRepositoryProtocol.swift
│   │   └── StorageRepositoryProtocol.swift
│   ├── Firebase/
│   │   ├── FirebaseMessagesRepository.swift   # Real-time listeners on messaging DB
│   │   ├── FirebaseCalendarRepository.swift   # Event CRUD + real-time listeners
│   │   ├── FirebaseUserRepository.swift       # User + company profile CRUD
│   │   ├── FirebaseNetworkRepository.swift    # Paginated user directory
│   │   ├── FirebaseAuthRepository.swift       # Firebase Auth wrapper
│   │   └── FirebaseStorageRepository.swift    # Image/document uploads
│   └── Salesforce/
│       └── SalesforceRepository.swift         # Salesforce CRM via Cloud Functions
│
├── ViewModels/
│   ├── AppViewModel.swift                 # Central facade: auth, onboarding, profile state
│   ├── AuthService.swift                  # Firebase Auth + GoogleSignIn wrapper
│   ├── ConversationsViewModel.swift       # Conversation list with real-time listener
│   ├── ConversationViewModel.swift        # Single chat: messages, media, meeting responses
│   ├── CalendarViewModel.swift            # Events display, iCal subscription
│   ├── ScheduleMeetingViewModel.swift     # Meeting scheduling + invite sending
│   ├── NetworkViewModel.swift             # User directory with pagination
│   ├── OnboardingViewModel.swift          # 5-step onboarding state + Salesforce prefill
│   └── NavigationRouter.swift             # Navigation state + theme (dark/light)
│
├── Views/
│   ├── Auth/
│   │   └── WelcomeView.swift
│   ├── Main/
│   │   ├── MainTabView.swift              # Bottom tab bar (Home, Discover, Network, Messages, Profile)
│   │   ├── Home/
│   │   │   ├── HomeView.swift             # Dashboard with upcoming events widget
│   │   │   ├── CalendarView.swift         # Full calendar with month/day views
│   │   │   └── CalendarSubscribeView.swift
│   │   ├── Discover/
│   │   │   └── MentorDiscoveryView.swift  # AI-powered search
│   │   ├── Network/
│   │   │   ├── NetworkView.swift          # Paginated user directory
│   │   │   └── UserProfileView.swift      # User detail + Connect button
│   │   ├── Messages/
│   │   │   ├── MessagesView.swift         # Conversation list with unread badges
│   │   │   ├── ConversationView.swift     # Chat thread with media + meeting scheduling
│   │   │   ├── FilteredConversationsView.swift
│   │   │   ├── NewConversationView.swift
│   │   │   ├── ScheduleMeetingView.swift  # Meeting scheduling modal
│   │   │   ├── MeetingInviteCard.swift    # Inline invite card (accept/decline/propose new)
│   │   │   └── ReceiptStatusView.swift    # Sent/delivered/read indicator
│   │   └── Profile/
│   │       ├── ProfileView.swift
│   │       ├── EditProfileView.swift
│   │       └── SettingsView.swift
│   └── Onboarding/
│       ├── OnboardingContainerView.swift
│       └── Steps/                         # PersonalInformation, CompanyBasics, CompanyBioLogo, Focus, ReviewFinish
│
├── Services/
│   ├── AnalyticsService.swift             # Typed Firebase Analytics events wrapper
│   └── MeetProviderService.swift          # Google Meet (Calendar API) + Teams (Graph API) integration
│
├── DesignSystem/
│   ├── Colors+Extensions.swift            # Brand colors with light/dark variants
│   ├── DesignSystem.swift                 # Spacing, corner radius, layout constants
│   ├── Typography.swift                   # Font styles
│   └── Components/                        # Reusable UI: CustomTextField, DashboardCard, SelectablePill, etc.
│
└── Resources/
    └── Localizable.xcstrings              # Xcode 15 string catalog (EN, ES, IT, FR, PT-BR)

functions/src/
├── index.ts                               # Admin init + all function exports
├── salesforce.ts                          # Salesforce CRM authorization gate
├── aiSearch.ts                            # searchUsersWithAI — Genkit + Gemini 2.0 Flash
├── messageFilter.ts                       # classifyMessage (Firestore trigger) + recheckConversation
├── meetProvider.ts                        # generateMeetLink — Google Calendar API + Microsoft Graph API
└── icalFeed.ts                            # HTTP iCal feed endpoint for calendar subscription

EndeavorAppTests/Mocks/
├── MockMessagesRepository.swift
└── MockCalendarRepository.swift
```

---

## Firestore Databases

Two completely separate Firestore instances — never mixed in code:

| Database ID | Purpose | Region |
|---|---|---|
| `(default)` | Users, companies, calendar events, UID mappings | `eur3` |
| `messaging` | Conversations, messages, bans | `eur3` |

```swift
let db = Firestore.firestore()                       // default — users, companies, events
let db = Firestore.firestore(database: "messaging")  // messaging only
```

---

## Cloud Functions

All functions deployed to region `europe-west1`.

| Function | Type | Description |
|---|---|---|
| `checkSalesforceAuthorization` | `onCall` | Checks if email is authorized in Salesforce |
| `getSalesforceContactData` | `onCall` | Fetches contact details by contactId |
| `checkAndFetchSalesforceContact` | `onCall` | Authorization check + contact fetch in one call |
| `checkUserExists` | `onCall` | Checks if Firebase user exists for an email |
| `searchUsersWithAI` | `onCallGenkit` | AI-powered user search using Genkit + Gemini 2.0 Flash |
| `classifyMessage` | Firestore trigger | Auto-runs on new message creation, classifies spam/safety |
| `recheckConversation` | `onCall` | Manual AI recheck for a conversation (7-day cooldown) |
| `generateMeetLink` | `onCall` | Creates Google Meet (Calendar API) or Teams (Graph API) meeting link |
| `icalFeed` | HTTP | Returns iCal feed for a user's calendar events |

### AI Stack
- **Framework**: Firebase Genkit v1.29.0
- **Model**: `gemini-2.0-flash` for all AI features
- **Secret**: `GOOGLE_GENAI_API_KEY` via `defineSecret`

---

## Meeting Integration

Meeting scheduling is end-to-end inside the chat:

1. Either user taps the calendar button in a conversation → `ScheduleMeetingView` opens
2. User sets title, date/time, duration, and selects a video provider (Google Meet, Teams, or none)
3. A `CalendarEvent` is saved to Firestore with `status: .pending`; a meeting invite message is sent in chat
4. The recipient sees a `MeetingInviteCard` with **Accept**, **Decline**, or **Propose New Time** actions
5. On Accept: the Cloud Function generates a real meeting link (Google Calendar API or Microsoft Graph API) and updates the event to `status: .confirmed`
6. The confirmed card shows a **Join Meeting** button that opens the link directly

**Google Meet**: requires Google Sign-In with `calendar.events` scope (incremental OAuth).
**Microsoft Teams**: requires MSAL authentication with `OnlineMeetings.ReadWrite` scope.

---

## Design System

All UI constants live in `DesignSystem.swift` and `Colors+Extensions.swift`:

### Colors
| Token | Light | Dark |
|---|---|---|
| `.brandPrimary` | `#00A896` | `#00D9C5` |
| `.background` | `#EFF5F4` | `#0A1628` |
| `.cardBackground` | `#FFFFFF` | `#1E2A3A` |
| `.inputBackground` | `#E0F0EE` | `#2A3647` |
| `.textPrimary` | `#0F172A` | `#FFFFFF` |
| `.textSecondary` | `#475569` | `#8B95A5` |

### Spacing
`xxSmall(4)` `xSmall(8)` `small(12)` `standard(16)` `medium(20)` `large(24)` `xLarge(32)` `xxLarge(40)` `xxxLarge(48)` `massive(64)`

### Corner Radius
`small(8)` `medium(12)` `large(16)` `xLarge(24)` `xxLarge(32)` `circle(100)`

---

## Localization

All user-facing strings use Xcode 15 String Catalogs (`Localizable.xcstrings`).

**Languages:** English (base), Spanish, Italian, French, Brazilian Portuguese

```swift
Text(String(localized: "key.name", defaultValue: "English fallback"))
```

Key namespaces: `auth.*`, `onboarding.*`, `home.*`, `network.*`, `discover.*`, `messages.*`, `profile.*`, `settings.*`, `schedule.*`, `meet.*`, `common.*`

---

## Prerequisites

- **Xcode 26** (iOS 17+ SDK)
- **Swift 5.x**
- **Node.js 22** + npm (for Cloud Functions)
- **Firebase CLI** (`npm install -g firebase-tools`)
- A Firebase project with Auth, Firestore (2 databases), Storage, Functions, App Check, and Performance enabled
- Salesforce connected app credentials (stored as Firebase Functions secrets)
- Google Cloud project with Calendar API enabled (for Google Meet)
- Azure app registration with `OnlineMeetings.ReadWrite` permission (for Teams)

---

## Setup & Installation

**1. Clone the repository**
```bash
git clone https://github.com/R3tr003/Endeavor-Antigravity.git
cd "Endeavor-Antigravity"
```

**2. Firebase configuration**
`GoogleService-Info.plist` is already included at `app/EndeavorApp/GoogleService-Info.plist`.

**3. Install Cloud Functions dependencies**
```bash
cd functions && npm install
```

**4. Make scripts executable**
```bash
chmod +x build_fast.sh run_app.sh run_tests.sh
```

---

## Running the App

### Quick compile check (no simulator — use after any code change)
```bash
./build_fast.sh
```

### Build + launch on simulator
```bash
./run_app.sh
```
Automatically detects an available iPhone simulator, builds, and launches the app. Options: `-u` force-uninstall previous build, `-s` skip uninstall prompt.

### Open in Xcode
```bash
open "app/app.xcodeproj"
```
Select the `app` scheme, choose an iPhone 17 simulator, press `Cmd+R`.

### Unit Tests
```bash
./run_tests.sh
```

---

## Cloud Functions

### Typecheck
```bash
cd functions && npm run build
```

### Deploy single function
```bash
firebase deploy --only functions:functionName
```

### Deploy all
```bash
firebase deploy --only functions
```

### Local emulators
```bash
firebase emulators:start      # Emulator UI at http://localhost:4010
cd functions && npm run genkit:start   # Genkit Developer UI
```

---

## Security

- **Firebase App Check** (AppAttest) enabled in production — disabled in DEBUG to allow simulator testing
- **Email Enumeration Protection** active — user existence checked via Firestore, not `fetchSignInMethods`
- **Firebase Auth accounts created only after onboarding completes** — no orphan accounts
- **Firestore security rules** enforce participant-only read/write on messaging; AI filter fields are Admin SDK-only
- **Storage rules** enforce per-user ownership for profile images; 5MB limit on profile images, 10MB on chat media
- **All errors** are typed as `AppError` enum cases with localized descriptions — no raw strings exposed to users

---

## Tech Stack

| Layer | Technology | Version |
|---|---|---|
| iOS | SwiftUI + MVVM | iOS 17+ |
| Language | Swift | 5.x |
| Auth | Firebase Auth + Google Sign-In + MSAL | — |
| Database | Cloud Firestore (2 instances) | firebase-ios-sdk 12.9.0 |
| Storage | Firebase Storage | — |
| Backend | Firebase Cloud Functions | TypeScript, Node.js 22 |
| AI Search | Genkit + `@genkit-ai/google-genai` | v1.29.0 |
| AI Filter | `@google/genai` direct | — |
| AI Model | Gemini 2.0 Flash | — |
| Auth Gate | Salesforce REST API via Cloud Functions | — |
| Analytics | Firebase Analytics + Performance | — |
| Integrity | Firebase App Check (AppAttest) | — |
| Image Loading | SDWebImageSwiftUI | 3.1.4 |
| Meeting (Google) | Google Calendar API (OAuth 2.0) | — |
| Meeting (Teams) | Microsoft Graph API (MSAL) | 2.9.0 |
| Dependencies | Swift Package Manager | — |
