#!/bin/bash

# Build the Proofreader app with icon
set -e

# Build the release binary
echo "Building release binary..."
swift build -c release

# Create app bundle structure
echo "Creating app bundle..."
APP_BUNDLE="Proofreader.app"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary
cp ".build/release/Proofreader" "$APP_BUNDLE/Contents/MacOS/"

# Copy icon
cp "Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/" 2>/dev/null || echo "Icon not found, continuing without icon"

# Create Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Proofreader</string>
    <key>CFBundleIdentifier</key>
    <string>com.gequ.Proofreader</string>
    <key>CFBundleName</key>
    <string>Proofreader</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2025 gequ. All rights reserved.</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon.icns</string>
</dict>
</plist>
EOF

echo "App bundle created: $APP_BUNDLE"
echo "To run: open $APP_BUNDLE"