#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

VERSION="$(tr -d '[:space:]' < VERSION)"
TAG="v$VERSION"

echo "=== GPT Computer $VERSION ==="
echo ""

echo "1. Building release..."
./build.sh release dmg

echo ""
echo "2. Validating DMG..."
xcrun stapler validate -q "build/GPT Computer.dmg" 2>/dev/null \
  || echo "  (not notarised — ./build.sh release ship does that)"

echo ""
echo "3. Creating GitHub release..."
gh release create "$TAG" \
  "build/GPT Computer.dmg" \
  "build/GPT Computer.zip" \
  "build/appcast.json" \
  --title "$TAG" \
  --notes "$(head -1 NOTES.md)" \
  || echo "  Release $TAG already exists"

echo ""
echo "4. Done — GPT Computer $VERSION published"
echo "   DMG:    build/GPT Computer.dmg"
echo "   ZIP:    build/GPT Computer.zip"
echo "   Notes:  NOTES.md (first paragraph → Settings)"