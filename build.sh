#!/bin/bash
set -e

echo "=== Building San (三) macOS Native App ==="

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$PROJECT_DIR/dist"
APP_BUNDLE="$BUILD_DIR/San.app"
DMG_PATH="$BUILD_DIR/San.dmg"

rm -rf "$BUILD_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$PROJECT_DIR/build/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

echo "Compiling Swift source code for San..."
SDK_PATH=$(xcrun --show-sdk-path 2>/dev/null || echo "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk")

swiftc -sdk "$SDK_PATH" \
       -target arm64-apple-macosx13.0 \
       -parse-as-library \
       -framework SwiftUI \
       -framework AppKit \
       -framework AVFoundation \
       -framework Combine \
       -framework UniformTypeIdentifiers \
       "$PROJECT_DIR/src/main.swift" \
       -o "$APP_BUNDLE/Contents/MacOS/San"

echo "Successfully compiled San.app!"

echo "Creating San.dmg Installer Package..."
DMG_TEMP_DIR="$BUILD_DIR/dmg_temp"
mkdir -p "$DMG_TEMP_DIR"
cp -R "$APP_BUNDLE" "$DMG_TEMP_DIR/"
ln -s /Applications "$DMG_TEMP_DIR/Applications"

hdiutil create -volname "San" -srcfolder "$DMG_TEMP_DIR" -ov -format UDZO "$DMG_PATH"
rm -rf "$DMG_TEMP_DIR"

echo "=== BUILD SUCCESSFUL ==="
echo "App: $APP_BUNDLE"
echo "DMG: $DMG_PATH"
