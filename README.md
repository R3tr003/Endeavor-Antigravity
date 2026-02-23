# Endeavor iOS App

Endeavor is a native iOS application built with SwiftUI, designed to support entrepreneurs with tools for networking, growth tracking, and AI-guided assistance.

## ✨ Recent Updates (Liquid Glass Redesign & Firebase Integration)
The application has recently undergone a major UI/UX overhaul and backend integration:
- **Liquid Glass Aesthetic:** Implemented a modern, dark-themed UI featuring ultra-thin materials, glassmorphism effects, and vibrant brand primary accents (teal/green).
- **Smooth Animations & Focus Tracking:** Added custom focus glows to all text inputs (Login, Onboarding, Profile Editing) and fluid background animations.
- **Firebase Authentication:** fully functional Email/Password and Google Sign-In flows, including password reset functionality.
- **Firestore Integration:** User and Company profiles are now fully synchronized with Firestore. Data is safely read and written asynchronously.
- **Robust Profile Editing:** Users can edit their personal and company details. Modifications are buffered locally and only saved to Firestore upon explicit confirmation.
- **Advanced Email Management:** Implemented a secure email change flow that checks Firestore for duplicate emails *before* re-authenticating the user and sending a verification link, bypassing Firebase Auth enumeration protection limits.
- **Onboarding Flow:** Polished multi-step onboarding process saving directly to the centralized `AppViewModel` and Firestore.

## 📋 Prerequisites
- **Xcode 15+** (iOS 17+ SDK)
- **Swift 5.9+**
- **Firebase Account** (for backend services)

## 🚀 Setup
1. **Clone the repository** to your local machine.
2. **Firebase Configuration**:
   - Ensure `GoogleService-Info.plist` is present in `app/EndeavorApp/`.
   - This file contains the configuration for Firebase Auth and Firestore.
   - *Note: If this file is missing, the app will crash on launch.*

## 🏃‍♂️ How to Run

### Option 1: Using Xcode (Recommended for Development)
1. Open the project file: `app/app.xcodeproj`.
2. Wait for Swift Package Manager (SPM) to resolve dependencies (Firebase).
3. Select the `app` scheme from the top bar.
4. Choose a Simulator (e.g., **iPhone 17 Pro**).
5. Press `Cmd + R` or click the Play button to build and run.

### Option 2: Using CLI Script (Fast Launch)
For a quick build and launch without opening the full Xcode UI, use the provided script:

```bash
./run_app.sh
```

This script will:
1. Automatically boot the **iPhone 17 Pro** simulator.
2. Build the project using `xcodebuild`.
3. Install and launch the app.

## 📂 Project Structure
- **`app/`**: The main project folder.
  - **`app.xcodeproj`**: The Xcode project file.
  - **`EndeavorApp/`**: Source code, Views, ViewModels, and Assets.
- **`run_app.sh`**: Shell script for command-line execution.
- **`.gitignore`**: Configured to ignore build artifacts and user data.

## 🛠 Tech Stack
- **Language**: Swift
- **UI Framework**: SwiftUI
- **Architecture**: MVVM (Model-View-ViewModel)
- **Backend**: Firebase (Authentication, Firestore)
- **Dependency Manager**: Swift Package Manager (SPM)
