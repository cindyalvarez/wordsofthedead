#!/bin/bash
# Builds Words of the Dead as a universal (arm64 + x86_64) macOS .app bundle.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APPDIR="$ROOT/WordsOfTheDead"
BUILD="$ROOT/build"
APP="$BUILD/WordsOfTheDead.app"
DEPLOY_TARGET="13.0"

echo "==> Regenerating vocabulary data"
python3 "$ROOT/tools/parse_vocab.py"

echo "==> Preparing bundle layout"
rm -rf "$BUILD"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

SRCS=$(find "$APPDIR/Sources" -name '*.swift')

echo "==> Compiling arm64 slice"
swiftc $SRCS -O -target "arm64-apple-macos$DEPLOY_TARGET" \
    -o "$BUILD/wotd-arm64"

echo "==> Compiling x86_64 slice"
swiftc $SRCS -O -target "x86_64-apple-macos$DEPLOY_TARGET" \
    -o "$BUILD/wotd-x86_64"

echo "==> Creating universal binary"
lipo -create "$BUILD/wotd-arm64" "$BUILD/wotd-x86_64" \
    -output "$APP/Contents/MacOS/WordsOfTheDead"

echo "==> Copying Info.plist and resources"
cp "$APPDIR/Resources/Info.plist" "$APP/Contents/Info.plist"
printf 'APPL????' > "$APP/Contents/PkgInfo"
cp "$ROOT/data/vocab.json" "$APP/Contents/Resources/"
cp "$ROOT/data/fun_definitions.json" "$APP/Contents/Resources/"
cp "$APPDIR/Resources/AppIcon.icns" "$APP/Contents/Resources/"
cp -r "$APPDIR/Resources/Sounds" "$APP/Contents/Resources/" 2>/dev/null || true

echo "==> Writing funsentences.txt"
python3 - "$ROOT/data/fun_definitions.json" "$ROOT/data/funsentences.txt" <<'PY'
import json, sys
defs = json.load(open(sys.argv[1]))["definitions"]
with open(sys.argv[2], "w") as f:
    for d in sorted(defs, key=lambda x: x["word"].lower()):
        f.write(f"{d['word']}\t{d['funDefinition']}\n")
PY
cp "$ROOT/data/funsentences.txt" "$APP/Contents/Resources/"
mkdir -p "$APP/Contents/Resources/backgrounds"
cp "$ROOT/reference-images/backgrounds/"*.jpg "$APP/Contents/Resources/backgrounds/" 2>/dev/null || true
cp "$ROOT/reference-images/backgrounds/"*.png "$APP/Contents/Resources/backgrounds/" 2>/dev/null || true
# Copy cutscene-specific images
cp "$ROOT/reference-images/accomplished.png" "$APP/Contents/Resources/" 2>/dev/null || true
cp "$ROOT/reference-images/zombies-escape.png" "$APP/Contents/Resources/" 2>/dev/null || true

echo "==> Checking for new background images"
bash "$ROOT/tools/check-backgrounds.sh" || true

rm -f "$BUILD/wotd-arm64" "$BUILD/wotd-x86_64"

echo "==> Registering app with LaunchServices"
# Clear any quarantine flag and (re)register so `open` reliably finds the bundle.
xattr -dr com.apple.quarantine "$APP" 2>/dev/null || true
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
[ -x "$LSREGISTER" ] && "$LSREGISTER" -f "$APP" || true

echo "==> Verifying architectures"
lipo -info "$APP/Contents/MacOS/WordsOfTheDead"

# Code signing (optional, for distribution)
if [ "${SIGN_FOR_DISTRIBUTION:-}" = "1" ]; then
    echo "==> Code Signing for Distribution"
    CERT_ID=$(security find-identity -v -p codesigning | grep "Developer ID" | head -1 | awk '{print $2}')
    if [ -n "$CERT_ID" ]; then
        echo "    Signing with certificate: $CERT_ID"
        codesign --deep --force --verify --verbose --sign "$CERT_ID" \
            --options runtime --timestamp "$APP"
        echo "✓ Signing complete"
        # Verify signing
        codesign -dv "$APP/Contents/MacOS/WordsOfTheDead" | grep -i "authority" || true
        
        # Preserve notarization ticket from deploy folder if it exists
        DEPLOY_APP="$ROOT/deploy/beta-1.0.0/WordsOfTheDead.app"
        if [ -d "$DEPLOY_APP/Contents/_CodeSignature" ]; then
            echo "==> Preserving notarization ticket"
            cp -r "$DEPLOY_APP/Contents/_CodeSignature" "$APP/Contents/" 2>/dev/null || true
            if codesign -dvvv "$APP" 2>&1 | grep -q "Notarization"; then
                echo "✓ Notarization ticket restored"
            fi
        fi
    else
        echo "⚠️  No Developer ID certificate found"
        echo "    For distribution, follow Phase 2 in BETA_DEPLOYMENT_GUIDE.md"
    fi
else
    echo "    (Code signing skipped. Use: SIGN_FOR_DISTRIBUTION=1 ./build.sh)"
fi

echo "==> Done: $APP"

# Launch the app automatically (absolute, properly-quoted path) unless disabled.
# This avoids the common "does not exist" error caused by a stray trailing space
# when manually typing `open build/WordsOfTheDead.app`.
if [ -z "${WOTD_NO_OPEN:-}" ]; then
    echo "==> Launching"
    open "$APP"
else
    echo "    Launch with:  open \"$APP\""
fi
