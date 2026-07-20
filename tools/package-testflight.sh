#!/bin/bash
# Builds and packages Words of the Dead for TestFlight (macOS App Store Connect).
#
# Usage:
#   ./tools/package-testflight.sh
#   ./tools/package-testflight.sh --skip-build
#   ./tools/package-testflight.sh --upload
#
# Required for signing:
#   - App Store app signing identity in keychain
#       (Apple Distribution OR 3rd Party Mac Developer Application)
#   - Installer signing identity in keychain
#       (Mac Installer Distribution OR 3rd Party Mac Developer Installer)
#   - APPSTORE_PROVISIONING_PROFILE path (macOS App Store provisioning profile)
#
# Optional for upload:
#   - ASC_KEY_ID, ASC_ISSUER_ID, ASC_PRIVATE_KEY_PATH

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/build/WordsOfTheDead.app"
APPSTORE_ENTITLEMENTS="$ROOT/WordsOfTheDead/Resources/WordsOfTheDead.appstore.entitlements"
DEPLOY_DIR="$ROOT/deploy/testflight"
UPLOAD=0
SKIP_BUILD=0

for arg in "$@"; do
    case "$arg" in
        --upload)
            UPLOAD=1
            ;;
        --skip-build)
            SKIP_BUILD=1
            ;;
        *)
            echo "Unknown argument: $arg"
            exit 1
            ;;
    esac
done

find_identity() {
    local pattern="$1"
    local policy="${2:-codesigning}"
    security find-identity -v -p "$policy" 2>/dev/null \
        | grep "$pattern" \
        | head -1 \
        | sed -E 's/.*"([^"]+)".*/\1/'
}

normalize_short_version() {
    local raw="$1"
    local base
    base="$(echo "$raw" | sed -E 's/[^0-9.].*$//')"
    # Keep only first three numeric components (App Store rule).
    local c1 c2 c3
    c1="$(echo "$base" | cut -d. -f1)"
    c2="$(echo "$base" | cut -d. -f2)"
    c3="$(echo "$base" | cut -d. -f3)"
    [ -z "$c1" ] && c1="1"
    [ -z "$c2" ] && c2="0"
    [ -z "$c3" ] && c3="0"
    echo "${c1}.${c2}.${c3}"
}

normalize_build_version() {
    local raw="$1"
    # App Store requires digits and up to 3 period-separated numeric components.
    if [[ "$raw" =~ ^[0-9]+(\.[0-9]+){0,2}$ ]]; then
        echo "$raw"
        return
    fi

    # Convert formats like 1.0.2-beta.2 -> 1.0.202
    local base suffix c1 c2 c3 sfx
    base="$(echo "$raw" | sed -E 's/[^0-9.].*$//')"
    suffix="$(echo "$raw" | sed -E 's/^[0-9.]+[^0-9]*//')"
    c1="$(echo "$base" | cut -d. -f1)"
    c2="$(echo "$base" | cut -d. -f2)"
    c3="$(echo "$base" | cut -d. -f3)"
    sfx="$(echo "$suffix" | sed -E 's/[^0-9]//g')"
    [ -z "$c1" ] && c1="1"
    [ -z "$c2" ] && c2="0"
    [ -z "$c3" ] && c3="0"
    [ -z "$sfx" ] && sfx="0"

    printf "%s.%s.%d\n" "$c1" "$c2" "$((10#$c3 * 100 + 10#$sfx))"
}

if [ "$SKIP_BUILD" -ne 1 ]; then
    echo "==> Building app"
    WOTD_NO_OPEN=1 "$ROOT/WordsOfTheDead/build.sh"
fi

if [ ! -d "$APP" ]; then
    echo "❌ App bundle not found at $APP"
    echo "   Build first: WOTD_NO_OPEN=1 ./WordsOfTheDead/build.sh"
    exit 1
fi

APP_BUNDLE_INFO_PLIST="$APP/Contents/Info.plist"
if [ ! -f "$APP_BUNDLE_INFO_PLIST" ]; then
    echo "❌ Built app Info.plist not found at $APP_BUNDLE_INFO_PLIST"
    exit 1
fi

if [ ! -f "$APPSTORE_ENTITLEMENTS" ]; then
    echo "❌ Missing App Store entitlements: $APPSTORE_ENTITLEMENTS"
    exit 1
fi

if [ -z "${APPSTORE_PROVISIONING_PROFILE:-}" ] || [ ! -f "${APPSTORE_PROVISIONING_PROFILE:-}" ]; then
    echo "❌ APPSTORE_PROVISIONING_PROFILE is required and must point to a file."
    echo "   Example: export APPSTORE_PROVISIONING_PROFILE=~/Downloads/WordsOfTheDead_AppStore.provisionprofile"
    exit 1
fi

APP_SIGN_ID="${APPSTORE_SIGN_ID:-}"
if [ -z "$APP_SIGN_ID" ]; then
    APP_SIGN_ID="$(find_identity "Apple Distribution" || true)"
fi
if [ -z "$APP_SIGN_ID" ]; then
    APP_SIGN_ID="$(find_identity "3rd Party Mac Developer Application" || true)"
fi
if [ -z "$APP_SIGN_ID" ]; then
    echo "❌ No App Store app signing identity found."
    echo "   Set APPSTORE_SIGN_ID or install Apple Distribution / 3rd Party Mac Developer Application cert."
    exit 1
fi

INSTALLER_SIGN_ID="${APPSTORE_INSTALLER_SIGN_ID:-}"
if [ -z "$INSTALLER_SIGN_ID" ]; then
    INSTALLER_SIGN_ID="$(find_identity "Mac Installer Distribution" basic || true)"
fi
if [ -z "$INSTALLER_SIGN_ID" ]; then
    INSTALLER_SIGN_ID="$(find_identity "3rd Party Mac Developer Installer" basic || true)"
fi
if [ -z "$INSTALLER_SIGN_ID" ]; then
    echo "❌ No App Store installer signing identity found."
    echo "   Set APPSTORE_INSTALLER_SIGN_ID or install Mac Installer Distribution / 3rd Party Mac Developer Installer cert."
    echo "   Check with: security find-identity -v -p basic | grep -E 'Mac Installer Distribution|3rd Party Mac Developer Installer'"
    exit 1
fi

RAW_VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP_BUNDLE_INFO_PLIST")"
RAW_BUILD_NUMBER="$(/usr/libexec/PlistBuddy -c 'Print CFBundleVersion' "$APP_BUNDLE_INFO_PLIST")"

VERSION="$(normalize_short_version "$RAW_VERSION")"
BUILD_NUMBER="$(normalize_build_version "$RAW_BUILD_NUMBER")"

if [ "$RAW_VERSION" != "$VERSION" ]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP_BUNDLE_INFO_PLIST"
fi
if [ "$RAW_BUILD_NUMBER" != "$BUILD_NUMBER" ]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$APP_BUNDLE_INFO_PLIST"
fi

echo "==> App Store version normalization"
echo "   CFBundleShortVersionString: $RAW_VERSION -> $VERSION"
echo "   CFBundleVersion: $RAW_BUILD_NUMBER -> $BUILD_NUMBER"

PKG_PATH="$DEPLOY_DIR/WordsOfTheDead-${VERSION}-${BUILD_NUMBER}-macos.pkg"

echo "==> Preparing app for App Store signing"
xattr -dr com.apple.quarantine "$APP" 2>/dev/null || true
xattr -d com.apple.quarantine "$APPSTORE_PROVISIONING_PROFILE" 2>/dev/null || true
cp "$APPSTORE_PROVISIONING_PROFILE" "$APP/Contents/embedded.provisionprofile"
xattr -d com.apple.quarantine "$APP/Contents/embedded.provisionprofile" 2>/dev/null || true
xattr -dr com.apple.quarantine "$APP" 2>/dev/null || true

PROFILE_PLIST="$(mktemp -t wotd-profile).plist"
SIGNING_ENTITLEMENTS="$(mktemp -t wotd-signing-entitlements).plist"
trap 'rm -f "$PROFILE_PLIST" "$SIGNING_ENTITLEMENTS"' EXIT

security cms -D -i "$APPSTORE_PROVISIONING_PROFILE" > "$PROFILE_PLIST"
cp "$APPSTORE_ENTITLEMENTS" "$SIGNING_ENTITLEMENTS"

# TestFlight requires the signed bundle entitlements to include the same
# application identifier that appears in the provisioning profile.
PROFILE_APP_ID_KEY=""
PROFILE_APP_ID="$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:com.apple.application-identifier' "$PROFILE_PLIST" 2>/dev/null || true)"
if [ -z "$PROFILE_APP_ID" ]; then
    PROFILE_APP_ID="$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:application-identifier' "$PROFILE_PLIST" 2>/dev/null || true)"
    PROFILE_APP_ID_KEY="application-identifier"
else
    PROFILE_APP_ID_KEY="com.apple.application-identifier"
fi
PROFILE_TEAM_ID="$(/usr/libexec/PlistBuddy -c 'Print :TeamIdentifier:0' "$PROFILE_PLIST" 2>/dev/null || true)"

if [ -n "$PROFILE_APP_ID" ] && [ -n "$PROFILE_APP_ID_KEY" ]; then
    /usr/libexec/PlistBuddy -c "Delete :com.apple.application-identifier" "$SIGNING_ENTITLEMENTS" >/dev/null 2>&1 || true
    /usr/libexec/PlistBuddy -c "Delete :application-identifier" "$SIGNING_ENTITLEMENTS" >/dev/null 2>&1 || true
    /usr/libexec/PlistBuddy -c "Add :$PROFILE_APP_ID_KEY string $PROFILE_APP_ID" "$SIGNING_ENTITLEMENTS"
fi

if [ -n "$PROFILE_TEAM_ID" ]; then
    /usr/libexec/PlistBuddy -c "Delete :com.apple.developer.team-identifier" "$SIGNING_ENTITLEMENTS" >/dev/null 2>&1 || true
    /usr/libexec/PlistBuddy -c "Add :com.apple.developer.team-identifier string $PROFILE_TEAM_ID" "$SIGNING_ENTITLEMENTS"
fi

echo "==> Signing app bundle"
codesign --force --deep \
    --sign "$APP_SIGN_ID" \
    --entitlements "$SIGNING_ENTITLEMENTS" \
    "$APP"

echo "==> Verifying code signature"
codesign --verify --deep --strict --verbose=2 "$APP"
spctl --assess --type execute --verbose "$APP" || true

echo "==> Creating signed installer package"
mkdir -p "$DEPLOY_DIR"
rm -f "$PKG_PATH"
productbuild \
    --component "$APP" /Applications \
    --sign "$INSTALLER_SIGN_ID" \
    "$PKG_PATH"

echo "==> Verifying installer package signature"
pkgutil --check-signature "$PKG_PATH"

echo "✅ TestFlight package ready:"
echo "   $PKG_PATH"

if [ "$UPLOAD" -eq 1 ]; then
    if [ -z "${ASC_KEY_ID:-}" ] || [ -z "${ASC_ISSUER_ID:-}" ] || [ -z "${ASC_PRIVATE_KEY_PATH:-}" ]; then
        echo "❌ --upload requires ASC_KEY_ID, ASC_ISSUER_ID, and ASC_PRIVATE_KEY_PATH."
        exit 1
    fi
    if [ ! -f "$ASC_PRIVATE_KEY_PATH" ]; then
        echo "❌ ASC_PRIVATE_KEY_PATH does not exist: $ASC_PRIVATE_KEY_PATH"
        exit 1
    fi

    KEY_BASENAME="$(basename "$ASC_PRIVATE_KEY_PATH")"
    KEY_DEST="$HOME/.appstoreconnect/private_keys/$KEY_BASENAME"
    mkdir -p "$HOME/.appstoreconnect/private_keys"
    cp "$ASC_PRIVATE_KEY_PATH" "$KEY_DEST"
    chmod 600 "$KEY_DEST"

    echo "==> Uploading package to App Store Connect"
    xcrun altool --upload-app \
        --type macos \
        --file "$PKG_PATH" \
        --apiKey "$ASC_KEY_ID" \
        --apiIssuer "$ASC_ISSUER_ID"

    echo "✅ Upload submitted. Track processing in App Store Connect → TestFlight."
fi
