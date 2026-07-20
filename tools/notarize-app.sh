#!/bin/bash
# Notarizes and staples a signed macOS app bundle.

set -euo pipefail

APP_PATH="${1:-}"

if [ -z "$APP_PATH" ] || [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: app bundle not found: ${APP_PATH:-<missing>}"
    exit 1
fi

ZIP_PATH="$(mktemp -t wotd-notarize).zip"
trap 'rm -f "$ZIP_PATH"' EXIT

build_notary_args() {
    if [ -n "${NOTARY_PROFILE:-}" ]; then
        NOTARY_ARGS=(--keychain-profile "$NOTARY_PROFILE")
        return 0
    fi

    if [ -n "${APPLE_ID:-}" ] && [ -n "${APPLE_APP_SPECIFIC_PASSWORD:-${APPLE_PASSWORD:-}}" ] && [ -n "${APPLE_TEAM_ID:-}" ]; then
        NOTARY_ARGS=(
            --apple-id "$APPLE_ID"
            --password "${APPLE_APP_SPECIFIC_PASSWORD:-${APPLE_PASSWORD:-}}"
            --team-id "$APPLE_TEAM_ID"
        )
        return 0
    fi

    return 1
}

NOTARY_ARGS=()
build_notary_args || {
    echo "❌ Error: notarization requested but no credentials were provided"
    echo "   Set NOTARY_PROFILE or APPLE_ID + APPLE_APP_SPECIFIC_PASSWORD + APPLE_TEAM_ID"
    exit 1
}

echo "   Creating notarization archive..."
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"

echo "   Submitting for notarization..."
xcrun notarytool submit "$ZIP_PATH" "${NOTARY_ARGS[@]}" --wait

echo "   Stapling notarization ticket..."
xcrun stapler staple "$APP_PATH"
xcrun stapler validate "$APP_PATH"

echo "   ✅ Notarization complete"
