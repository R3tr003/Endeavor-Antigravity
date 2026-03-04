# Endeavor iOS App

Endeavor is a native iOS application built with SwiftUI for entrepreneurs. It provides networking, real-time messaging, mentorship discovery, and AI-guided assistance — with a curated invite-only access model gated through Salesforce.

---

## ✨ Key Features

- **Invite-only Access via Salesforce** — new users are authorized against a Salesforce CRM before any account is created
- **Deferred Firebase Account Creation** — Firebase Auth accounts are created only after the full onboarding is completed
- **Google Sign-In & Email/Password Auth** — full support for both flows
- **Salesforce Prefill** — onboarding forms are pre-populated from the user's Salesforce Contact record
- **Firestore Profiles** — user and company profiles stored and synced in Cloud Firestore
- **Real-time Messaging** — chat between users via a secondary Firestore database (`messaging`)
- **Firebase Cloud Messaging (FCM)** — push notifications for new messages and events
- **Firebase Storage** — profile image upload and CDN delivery
- **Firebase App Check** — AppAttest in production, bypassed in DEBUG for local development
- **Mentor Discovery** — browse and connect with mentors filtered by expertise and industry
- **Analytics** — Firebase Analytics events for login, signup, onboarding, and Salesforce prefill

---

## 🔐 Authentication & Onboarding Flow

### New Users (Email/Password)
1. User enters email + password on the Welcome screen
2. App checks Salesforce via Cloud Function (`checkAndFetchSalesforceContact`)
3. If **authorized**: credentials are stored in pending state — **no Firebase account is created yet**
4. User completes the multi-step onboarding (5 steps, Salesforce-prefilled)
5. On `completeOnboarding()`: Firebase account is created, then user + company are saved to Firestore

### New Users (Google Sign-In)
1. User taps "Continue with Google"
2. App checks Firestore for an existing profile — if none, proceeds to Salesforce check
3. If **authorized**: Google tokens + profile data (name, photo) are stored in pending state
4. User sees Google name and photo pre-loaded in onboarding steps
5. On `completeOnboarding()`: Google Sign-In is finalized with Firebase, then Firestore is saved

### Returning Users (Email or Google)
- Email: direct sign-in via Firebase Auth → Firestore profile loaded → main app
- Google: Firestore check confirms existing profile → Google Sign-In → Firestore profile loaded → main app
- **Salesforce is never called for returning users** (fast path)

---

## 🏗 Architecture

| Layer | Pattern |
|---|---|
| UI | SwiftUI (MVVM) |
| State Management | `AppViewModel` (Facade) + sub-ViewModels |
| Auth | `AuthService` → `FirebaseAuthRepository` |
| Data | `UserRepository`, `MessagesRepository`, `StorageRepository` |
| Backend | Firebase (Auth, Firestore, Functions, Storage, FCM) |
| Authorization | Salesforce via Firebase Cloud Functions (europe-west1) |
| Image Loading | SDWebImage + SDWebImageSwiftUI |

### Key Files
```
app/EndeavorApp/
├── App.swift                        # Routing logic & app entry point
├── ViewModels/
│   ├── AppViewModel.swift           # Central facade: auth, onboarding, profile
│   ├── AuthService.swift            # Firebase Auth + Google Sign-In wrapper
│   └── OnboardingViewModel.swift    # Multi-step onboarding state & draft persistence
├── Repositories/
│   ├── UserRepository.swift         # Firestore user + company CRUD
│   ├── MessagesRepository.swift     # Real-time chat (secondary Firestore DB)
│   ├── StorageRepository.swift      # Firebase Storage upload
│   └── Salesforce/
│       └── SalesforceRepository.swift  # Salesforce Cloud Function calls
├── Views/
│   ├── Onboarding/                  # 5-step onboarding container + steps
│   ├── Home/                        # Main dashboard
│   ├── Network/                     # User directory & connections
│   ├── Messages/                    # Real-time chat views
│   ├── Profile/                     # Profile + Edit Profile views
│   └── Settings/                    # App settings
functions/
└── src/
    ├── index.ts                     # Cloud Functions entry point
    └── salesforce.ts                # Salesforce OAuth + contact fetch logic
```

---

## 📋 Prerequisites

- **Xcode 16+** (iOS 17+ SDK)
- **Swift 5.10+**
- **Firebase CLI** (`npm install -g firebase-tools`)
- A **Firebase project** with Auth, Firestore (2 databases), Storage, Functions, and FCM enabled
- **Salesforce connected app** credentials (stored as Firebase Functions secrets)

---

## 🚀 Setup & Installation

**1. Clone the repository**
```bash
git clone https://github.com/R3tr003/Endeavor-Antigravity.git
cd "Endeavor-Antigravity"
```

**2. Add Firebase configuration**
Place the `GoogleService-Info.plist` (from Firebase Console) in:
```bash
cp ~/Downloads/GoogleService-Info.plist "app/EndeavorApp/"
```
> ⚠️ The app will crash on launch without this file.

**3. Make the run script executable**
```bash
chmod +x run_app.sh
```

---

## 🏃 How to Run

### CLI (Recommended)
```bash
./run_app.sh
```
Automatically boots an iPhone 17 Pro simulator, resolves SPM dependencies, builds, and launches the app.

### Xcode
```bash
open "app/app.xcodeproj"
```
Select the `app` scheme, choose an iPhone simulator, and press `Cmd + R`.

---

## ☁️ Cloud Functions

Functions are deployed in the `europe-west1` region:

| Function | Description |
|---|---|
| `checkAndFetchSalesforceContact` | Checks Salesforce authorization + fetches contact data in one call |
| `checkSalesforceAuthorization` | Authorization check only |
| `getSalesforceContactData` | Fetches contact details by contactId |

Deploy with:
```bash
cd functions && firebase deploy --only functions
```

---

## 🗄 Firestore Databases

| Database ID | Purpose |
|---|---|
| `(default)` | User profiles, company profiles, UID mappings |
| `messaging` | Real-time chat conversations and messages |

---

## 🔒 Security Notes

- **Firebase App Check** is enabled in production (AppAttest). Disabled in DEBUG builds to avoid simulator issues.
- **Email Enumeration Protection** is active in Firebase Auth — user existence is checked via Firestore, not `fetchSignInMethods`.
- Firebase Auth accounts are **never created before onboarding is completed** — no orphan accounts in the console.
- Firestore security rules enforce that users can only read/write their own documents.

---

## 🛠 Tech Stack

| | |
|---|---|
| Language | Swift 5.10 |
| UI | SwiftUI |
| Architecture | MVVM with Facade (AppViewModel) |
| Auth | Firebase Authentication + Google Sign-In SDK |
| Database | Cloud Firestore |
| Storage | Firebase Storage |
| Notifications | Firebase Cloud Messaging |
| Functions | Firebase Cloud Functions (TypeScript) |
| Authorization | Salesforce REST API (via Cloud Functions) |
| Image Loading | SDWebImage |
| Analytics | Firebase Analytics |
| Dependencies | Swift Package Manager (SPM) |
