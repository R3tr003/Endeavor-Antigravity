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
# 2. Check/Boot Simulator
echo "📱 Checking Simulator..."
SIMULATOR_ID="0C3A9573-3B4B-4F90-B8D3-D50ECE76B712"

echo "📲 Using Simulator ID: $SIMULATOR_ID"

# Check if booted
IS_BOOTED=$(xcrun simctl list devices | grep "$SIMULATOR_ID" | grep "Booted")
if [ -z "$IS_BOOTED" ]; then
    echo "🔌 Booting simulator..."
    xcrun simctl boot "$SIMULATOR_ID"
    echo "⏳ Waiting for simulator to boot..."
    sleep 10 # Give it a moment
    open -a Simulator # Ensure the Simulator.app GUI is visible
fi

# 3. Build with xcodebuild
echo "🔨 Building with Xcode..."

xcodebuild build \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME_NAME" \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -sdk iphonesimulator \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  -quiet

if [ $? -ne 0 ]; then
    echo "❌ Build failed."
    exit 1
fi

echo "✅ Build successful!"

# 4. Locate Application Bundle
# The path inside DerivedData depends on the architecture/SDK
APP_BUNDLE=$(find "$DERIVED_DATA_PATH/Build/Products" -name "$APP_NAME.app" | head -n 1)

if [ -z "$APP_BUNDLE" ]; then
     echo "❌ Could not find .app bundle in $DERIVED_DATA_PATH"
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
