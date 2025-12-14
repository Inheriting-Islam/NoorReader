#!/bin/bash
# run.sh - Build and run NoorReader
# بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ

set -e

echo "بِسْمِ اللَّهِ - Building NoorReader..."

# Build the project
xcodebuild -scheme NoorReader -configuration Debug build -quiet

# Find and run the built app
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "NoorReader.app" -path "*/Debug/*" 2>/dev/null | head -1)

if [ -z "$APP_PATH" ]; then
    echo "Error: Could not find built app. Make sure to create the Xcode project first."
    exit 1
fi

echo "Running NoorReader..."
open "$APP_PATH"
