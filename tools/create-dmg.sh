#!/bin/bash
# Creates a professional DMG installer for Words of the Dead
# Usage: ./tools/create-dmg.sh
# Output: WordsOfTheDead-1.0.2-beta.1.dmg

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_PATH="$ROOT/build/WordsOfTheDead.app"
DMG_NAME="WordsOfTheDead-1.0.2-beta.1.dmg"
TEMP_DIR="/tmp/wotd_dmg_$$"

# Verify app exists
if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: App not found at $APP_PATH"
    echo "   Please build first: ./WordsOfTheDead/build.sh"
    exit 1
fi

echo "📦 Creating DMG installer..."

# Create temporary directory
mkdir -p "$TEMP_DIR"
trap "rm -rf $TEMP_DIR" EXIT

# Copy app
cp -r "$APP_PATH" "$TEMP_DIR/"

# Create symlink to Applications folder
ln -s /Applications "$TEMP_DIR/Applications"

# Add background image if available
if [ -f "$ROOT/reference-images/backgrounds/bg1.jpg" ]; then
    mkdir -p "$TEMP_DIR/.background"
    cp "$ROOT/reference-images/backgrounds/bg1.jpg" "$TEMP_DIR/.background/background.jpg"
fi

# Create DMG (UDZO format is compressed, good for distribution)
echo "   Building disk image (this may take a moment)..."
hdiutil create -volname "Words of the Dead" \
    -srcfolder "$TEMP_DIR" \
    -ov -format UDZO \
    -imagekey zlib-level=9 \
    "$ROOT/$DMG_NAME"

# Sign the DMG itself when a distribution certificate is available.
SIGN_ID="Developer ID Application: CYNTHIA LYNN ALVAREZ (5393XLUVZ7)"
if [ -f "$ROOT/$DMG_NAME" ]; then
    echo "   Signing disk image..."
    codesign --force --sign "$SIGN_ID" --timestamp "$ROOT/$DMG_NAME"
fi

# Verify DMG was created
if [ -f "$ROOT/$DMG_NAME" ]; then
    SIZE=$(du -h "$ROOT/$DMG_NAME" | cut -f1)
    echo "✅ DMG created successfully"
    echo "   Location: $ROOT/$DMG_NAME"
    echo "   Size: $SIZE"
else
    echo "❌ Error: Failed to create DMG"
    exit 1
fi
