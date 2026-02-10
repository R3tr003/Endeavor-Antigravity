#!/bin/bash

# ============================================================
# Firebase App Distribution Script for Endeavor iOS App
# ============================================================
# This script builds an IPA and uploads it to Firebase App Distribution.
#
# PREREQUISITES:
# 1. Firebase CLI installed: npm install -g firebase-tools
# 2. Logged into Firebase: firebase login
# 3. Valid Apple Developer account with provisioning profile
# 4. ExportOptions.plist configured (see below)
#
# USAGE:
#   ./distribute_app.sh [OPTIONS]
#
# OPTIONS:
#   -t, --testers "email1,email2"   Comma-separated list of tester emails
#   -g, --groups "group1,group2"    Comma-separated list of tester groups
#   -n, --notes "Release notes"     Release notes for this build
#   -h, --help                      Show this help message
#
# ============================================================

set -e  # Exit on any error

# Configuration
APP_NAME="app"
BUNDLE_ID="com.endeavor.app"
PROJECT_PATH="app/app.xcodeproj"
SCHEME_NAME="app"
FIREBASE_APP_ID="1:306155509671:ios:4c7b22f8e411a73aac8882"  # From GoogleService-Info.plist
BUILD_DIR="Build"
ARCHIVE_PATH="$BUILD_DIR/Endeavor.xcarchive"
IPA_PATH="$BUILD_DIR/Endeavor.ipa"
EXPORT_OPTIONS_PATH="ExportOptions.plist"

# Default values
TESTERS=""
GROUPS=""
RELEASE_NOTES="New build from Endeavor team"

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -t|--testers) TESTERS="$2"; shift ;;
        -g|--groups) GROUPS="$2"; shift ;;
        -n|--notes) RELEASE_NOTES="$2"; shift ;;
        -h|--help)
            echo "Usage: ./distribute_app.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -t, --testers \"email1,email2\"   Comma-separated list of tester emails"
            echo "  -g, --groups \"group1,group2\"    Comma-separated list of tester groups"
            echo "  -n, --notes \"Release notes\"     Release notes for this build"
            echo "  -h, --help                      Show this help message"
            echo ""
            echo "Examples:"
            echo "  ./distribute_app.sh -t \"user@example.com\" -n \"Bug fixes\""
            echo "  ./distribute_app.sh -g \"internal-testers\" -n \"New feature release\""
            exit 0
            ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

echo "🚀 Firebase App Distribution - Endeavor iOS"
echo "============================================"

# Step 1: Check prerequisites
echo ""
echo "📋 Step 1: Checking prerequisites..."

# Check Firebase CLI
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Install with: npm install -g firebase-tools"
    exit 1
fi
echo "  ✅ Firebase CLI found"

# Check if logged in to Firebase
if ! firebase projects:list &> /dev/null; then
    echo "❌ Not logged in to Firebase. Run: firebase login"
    exit 1
fi
echo "  ✅ Firebase authentication OK"

# Check ExportOptions.plist exists
if [ ! -f "$EXPORT_OPTIONS_PATH" ]; then
    echo "⚠️  ExportOptions.plist not found. Creating template..."
    cat > "$EXPORT_OPTIONS_PATH" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>ad-hoc</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>provisioningProfiles</key>
    <dict>
        <key>com.endeavor.app</key>
        <string>YOUR_PROVISIONING_PROFILE_NAME</string>
    </dict>
</dict>
</plist>
EOF
    echo ""
    echo "📝 IMPORTANT: Edit ExportOptions.plist with your:"
    echo "   - Team ID (Apple Developer Portal > Membership)"
    echo "   - Provisioning Profile name (for Ad-Hoc distribution)"
    echo ""
    echo "Once configured, run this script again."
    exit 1
fi
echo "  ✅ ExportOptions.plist found"

# Step 2: Clean previous build artifacts
echo ""
echo "🧹 Step 2: Cleaning previous builds..."
rm -rf "$BUILD_DIR"/*.xcarchive
rm -rf "$BUILD_DIR"/*.ipa
echo "  ✅ Cleaned"

# Step 3: Build Archive
echo ""
echo "🔨 Step 3: Building archive (this may take a few minutes)..."

# Ensure we use generic device destination to build ARM64 for devices
xcodebuild archive \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME_NAME" \
    -archivePath "$ARCHIVE_PATH" \
    -sdk iphoneos \
    -configuration Release \
    -destination "generic/platform=iOS" \
    CODE_SIGN_STYLE=Automatic \
    -quiet

if [ ! -d "$ARCHIVE_PATH" ]; then
    echo "❌ Archive failed. Check Xcode signing settings."
    exit 1
fi
echo "  ✅ Archive created: $ARCHIVE_PATH"

# Step 4: Export IPA
echo ""
echo "📦 Step 4: Exporting IPA..."

xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$BUILD_DIR" \
    -exportOptionsPlist "$EXPORT_OPTIONS_PATH" \
    -quiet

# Find the exported IPA
EXPORTED_IPA=$(find "$BUILD_DIR" -name "*.ipa" -type f | head -n 1)

if [ -z "$EXPORTED_IPA" ]; then
    echo "❌ IPA export failed. Check ExportOptions.plist and signing."
    exit 1
fi
echo "  ✅ IPA exported: $EXPORTED_IPA"

# Step 5: Upload to Firebase App Distribution
echo ""
echo "☁️  Step 5: Uploading to Firebase App Distribution..."

# Build the Firebase command
FIREBASE_CMD="firebase appdistribution:distribute \"$EXPORTED_IPA\" --app \"$FIREBASE_APP_ID\""

if [ -n "$TESTERS" ]; then
    FIREBASE_CMD="$FIREBASE_CMD --testers \"$TESTERS\""
fi

if [ -n "$GROUPS" ]; then
    FIREBASE_CMD="$FIREBASE_CMD --groups \"$GROUPS\""
fi

if [ -n "$RELEASE_NOTES" ]; then
    FIREBASE_CMD="$FIREBASE_CMD --release-notes \"$RELEASE_NOTES\""
fi

echo "  Running: $FIREBASE_CMD"
eval $FIREBASE_CMD

# Step 6: Success!
echo ""
echo "============================================"
echo "🎉 Distribution Complete!"
echo "============================================"
echo ""
echo "📱 Your app has been uploaded to Firebase App Distribution."
echo "   Testers will receive an email invitation to download the app."
echo ""
echo "🔗 View releases at:"
echo "   https://console.firebase.google.com/project/endeavor-app-prod/appdistribution"
echo ""
