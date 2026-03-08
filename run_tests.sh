#!/bin/bash

echo "🚀 Starting Tests for Endeavor..."
echo "📱 Checking Simulator..."

# Find an available iOS Simulator. We'll try to find a booted one first, or just use iPhone 15 Pro.
SIMULATOR_ID=$(xcrun simctl list devices | grep "Booted" | grep -v "watchOS" | grep -v "tvOS" | head -n 1 | grep -oE "[A-Z0-9]{8}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{12}")

if [ -z "$SIMULATOR_ID" ]; then
    echo "No booted simulator found. Will use latest iPhone 15 Pro."
    DESTINATION="platform=iOS Simulator,name=iPhone 15 Pro"
else
    echo "📲 Using Booted Simulator ID: $SIMULATOR_ID"
    DESTINATION="platform=iOS Simulator,id=$SIMULATOR_ID"
fi

echo "🔨 Running tests via xcodebuild..."
xcodebuild test \
  -project app/app.xcodeproj \
  -scheme app \
  -destination "$DESTINATION"

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo "✅ All tests passed!"
else
    echo "❌ Tests failed or no Test Target configured."
    echo ""
    echo "If it says 'Scheme app is not currently configured for the test action':"
    echo "You must go into Xcode -> File -> New -> Target -> Unit Testing Bundle and add the EndeavorAppTests folder."
fi
