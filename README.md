# Endeavor iOS App

Endeavor is a native iOS application built with SwiftUI, designed to support entrepreneurs with tools for networking, growth tracking, and AI-guided assistance.

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
