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

## 🚀 Setup & Installation
Follow these exact steps in your terminal to get the app running from scratch.

**1. Clone the repository**
```bash
git clone https://github.com/R3tr003/Endeavor-Antigravity.git
cd "Endeavor-Antigravity"
```

**2. Firebase Configuration**
You must have the `GoogleService-Info.plist` file (provided by the team or downloaded from Firebase Console) placed in the project directory:
```bash
# Ensure you copy your plist file into the correct directory:
cp ~/Downloads/GoogleService-Info.plist "app/EndeavorApp/"
```
*(Note: If this file is missing, the app will crash on launch.)*

**3. Make the run script executable**
Give execution permissions to the build script:
```bash
chmod +x run_app.sh
```

## 🏃‍♂️ How to Run

### Option 1: Fast CLI Launch (Recommended)
From the root of the project folder (`Endeavor-Antigravity`), simply run:
```bash
./run_app.sh
```
This script will automatically:
- Boot an iOS 17/iPhone 17 Pro simulator.
- Resolve Swift Package Manager (SPM) dependencies.
- Build the app via `xcodebuild` (showing only warnings/errors).
- Install and launch the `.app` bundle.

### Option 2: Using Xcode UI
1. Open the project file: 
```bash
open "app/app.xcodeproj"
```
2. Wait for Xcode to finish resolving the Firebase SPM dependencies.
3. Select the `app` scheme and an `iPhone` simulator from the top bar.
4. Press `Cmd + R` to build and run.

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
