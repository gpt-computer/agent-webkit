#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
APP="build/GPT Computer.app"
NAME="GPT Computer"
swift build -c debug
BINARY=".build/debug/GPT Computer"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BINARY" "$APP/Contents/MacOS/$NAME"
ICONSET="build/AppIcon.iconset"
rm -rf "$ICONSET"
swift Icon/icon.swift "$ICONSET" > /dev/null
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
rm -rf "$ICONSET"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>$NAME</string>
  <key>CFBundleDisplayName</key><string>$NAME</string>
  <key>CFBundleExecutable</key><string>$NAME</string>
  <key>CFBundleIdentifier</key><string>com.khulnasoft.gptcomputer</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSApplicationCategoryType</key><string>public.app.category.productivity</string>
  <key>NSHumanReadableCopyright</key><string>© KhulnaSoft · GPT Computer</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>CFBundleURLTypes</key>
  <array>
    <dict>
      <key>CFBundleURLName</key><string>Web address</string>
      <key>CFBundleURLSchemes</key>
      <array><string>http</string><string>https</string></array>
    </dict>
  </array>
  <key>CFBundleDocumentTypes</key>
  <array>
    <dict>
      <key>CFBundleTypeName</key><string>Web page</string>
      <key>CFBundleTypeRole</key><string>Viewer</string>
      <key>LSItemContentTypes</key>
      <array><string>public.html</string><string>com.apple.web-internet-location</string></array>
    </dict>
  </array>
  <key>NSAppTransportSecurity</key>
  <dict><key>NSAllowsArbitraryLoads</key><true/></dict>
  <key>NSCameraUsageDescription</key>
  <string>Websites you visit can ask to use your camera. GPT Computer asks you the first time each site does and keeps your answer; Settings › Privacy forgets them.</string>
  <key>NSMicrophoneUsageDescription</key>
  <string>Websites you visit can ask to use your microphone. GPT Computer asks you the first time each site does and keeps your answer; Settings › Privacy forgets them.</string>
  <key>NSDownloadsFolderUsageDescription</key>
  <string>Files you download are saved to your Downloads folder.</string>
</dict>
</plist>
PLIST
ENTITLEMENTS="GPT Computer.entitlements"
if [ -f "GPT Computer.provisionprofile" ]; then
  cp "GPT Computer.provisionprofile" "$APP/Contents/embedded.provisionprofile"
  ENTITLEMENTS="GPT Computer.passkeys.entitlements"
fi
if [ -n "$(security find-identity -v -p codesigning 2>/dev/null | grep -o '"Developer ID Application: [^"]*"' | head -1 | tr -d '"' || true)" ]; then
  codesign --force --deep --timestamp --options runtime \
    --entitlements "$ENTITLEMENTS" \
    --sign "$(security find-identity -v -p codesigning 2>/dev/null | grep -o '"Developer ID Application: [^"]*"' | head -1 | tr -d '"')" "$APP"
else
  codesign --force --deep --sign - "$APP" 2>/dev/null || true
fi
open -a "$APP" --args --probeless