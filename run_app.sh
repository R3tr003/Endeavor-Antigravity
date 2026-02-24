#!/bin/bash

# Configuration
APP_NAME="app" # Product Name in Xcode
DISPLAY_NAME="Endeavor"
BUNDLE_ID="com.endeavor.app"
SIMULATOR_NAME="iPhone 15 Pro"
PROJECT_PATH="app/app.xcodeproj"
SCHEME_NAME="app"
DERIVED_DATA_PATH="Build"

# Parse command line arguments
FORCE_UNINSTALL=false
SKIP_UNINSTALL=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -u|--uninstall) FORCE_UNINSTALL=true ;;
        -s|--skip-uninstall) SKIP_UNINSTALL=true ;;
        -h|--help)
            echo "Usage: ./run_app.sh [OPTIONS]"
            echo "Options:"
            echo "  -u, --uninstall       Force uninstall before installing"
            echo "  -s, --skip-uninstall  Skip uninstall prompt"
            echo "  -h, --help            Show this help"
            exit 0
            ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

echo "🚀 Starting Build Process for $DISPLAY_NAME..."

# 1. Clean previous build artifact location (optional, speeds up if kept, but cleaner if removed)
# rm -rf "$DERIVED_DATA_PATH" 

# 2. Check/Boot Simulator
echo "📱 Checking Simulator..."

# Get available simulators and pick one
# Priority: 1. Booted iPhone, 2. Named $SIMULATOR_NAME, 3. Any available iPhone
SIMULATOR_ID=$(xcrun simctl list devices available -j | python3 -c '
import json, sys
data = json.load(sys.stdin)
devices = data.get("devices", {})
# 1. Look for booted iPhones
for runtime, dlist in devices.items():
    if "iOS" in runtime:
        for d in dlist:
            if d.get("state") == "Booted":
                print(d.get("udid"))
                sys.exit(0)
# 2. Look for named simulator
target_name = sys.argv[1] if len(sys.argv) > 1 else ""
if target_name:
    for runtime, dlist in devices.items():
        if "iOS" in runtime:
            for d in dlist:
                if target_name in d.get("name", ""):
                    print(d.get("udid"))
                    sys.exit(0)
# 3. Fallback to any available iPhone
for runtime, dlist in devices.items():
    if "iOS" in runtime:
        for d in dlist:
            print(d.get("udid"))
            sys.exit(0)
' "$SIMULATOR_NAME")

if [ -z "$SIMULATOR_ID" ]; then
    echo "❌ No available simulators found."
    exit 1
fi

# Get details for the destination specifier
ACTUAL_SIM_NAME=$(xcrun simctl list devices | grep "$SIMULATOR_ID" | head -n 1 | sed -E 's/^[[:space:]]*//; s/ \([A-Fa-f0-9-]+\).*//')
SIM_OS_VERSION=$(xcrun simctl list devices | grep -B 10 "$SIMULATOR_ID" | grep "iOS" | head -n 1 | sed -E 's/-- iOS //; s/ --//')

echo "📲 Using Simulator: $ACTUAL_SIM_NAME ($SIMULATOR_ID) on iOS $SIM_OS_VERSION"

# Check if booted
IS_BOOTED=$(xcrun simctl list devices | grep "$SIMULATOR_ID" | grep "Booted")
if [ -z "$IS_BOOTED" ]; then
    echo "🔌 Booting simulator..."
    xcrun simctl boot "$SIMULATOR_ID"
    echo "⏳ Waiting for simulator to boot..."
    sleep 5
fi

# Always ensure the Simulator app is open and in the foreground
open -a Simulator
# 3. Build with xcodebuild
echo "🔨 Building with Xcode..."

DESTINATION="platform=iOS Simulator,id=$SIMULATOR_ID"
echo "📍 Destination: $DESTINATION"

xcodebuild build \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME_NAME" \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  -quiet

if [ $? -ne 0 ]; then
    echo "❌ Build failed."
    exit 1
fi

echo "✅ Build successful!"

# 4. Locate Application Bundle
# Search in the derived data path for the .app bundle
echo "🔍 Searching for App Bundle in $DERIVED_DATA_PATH..."
APP_BUNDLE=$(find "$DERIVED_DATA_PATH" -name "$APP_NAME.app" -type d | head -n 1)

if [ -z "$APP_BUNDLE" ]; then
     echo "❌ Could not find $APP_NAME.app in $DERIVED_DATA_PATH"
     # Fallback: check default DerivedData just in case
     DEFAULT_DD="$HOME/Library/Developer/Xcode/DerivedData"
     echo "🔍 Checking fallback location: $DEFAULT_DD..."
     APP_BUNDLE=$(find "$DEFAULT_DD" -name "$APP_NAME.app" -type d -mmin -60 | head -n 1)
fi

if [ -z "$APP_BUNDLE" ]; then
     echo "❌ Could not find .app bundle anywhere."
     exit 1
fi

echo "📦 Found App Bundle: $APP_BUNDLE"

# 5. Uninstall prompt (interactive)
if [ "$FORCE_UNINSTALL" = true ]; then
    echo "🗑️  Uninstalling previous version..."
    xcrun simctl uninstall "$SIMULATOR_ID" "$BUNDLE_ID" 2>/dev/null || true
elif [ "$SKIP_UNINSTALL" = false ]; then
    # Auto-yes for speed during dev loop, uncomment line below to skip prompt
    # response="y"
    echo "❓ Uninstall previous version? (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "🗑️  Uninstalling previous version..."
        xcrun simctl uninstall "$SIMULATOR_ID" "$BUNDLE_ID" 2>/dev/null || true
    fi
fi

# 6. Install and Launch
echo "💾 Installing..."
xcrun simctl install "$SIMULATOR_ID" "$APP_BUNDLE"

echo "🚀 Launching..."
# Launch the app
xcrun simctl launch "$SIMULATOR_ID" "$BUNDLE_ID"

echo ""
echo "🎉 Endeavor is running!"
echo "🛑 Press [ENTER] to stop the app (Simulator will stay open)..."

# Wait for user input
read -r

# Cleanup
echo "🔌 Stopping app..."
xcrun simctl terminate "$SIMULATOR_ID" "$BUNDLE_ID" 2>/dev/null
echo "✅ App stopped. Simulator is ready for next run."