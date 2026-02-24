#!/bin/bash

# Fast build script to check for syntax errors without launching the simulator
echo "🔨 Running Fast Build..."

xcodebuild build \
  -project "app/app.xcodeproj" \
  -scheme "app" \
  -sdk iphonesimulator \
  -quiet

if [ $? -eq 0 ]; then
    echo "✅ Build Succeeded!"
else
    echo "❌ Build Failed."
    exit 1
fi
