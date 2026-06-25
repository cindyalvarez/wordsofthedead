#!/bin/bash
# Beta Deployment Orchestration Script
# Automates the complete beta deployment process: build, test, sign, package, deploy
#
# Usage:
#   ./tools/deploy-beta.sh              # Complete deployment flow
#   ./tools/deploy-beta.sh --quick      # Skip manual testing prompts
#   ./tools/deploy-beta.sh --sign       # Enable code signing
#   ./tools/deploy-beta.sh --dmg-only   # Only create DMG (app already built)
#
# Requirements:
#   - macOS 13.0+
#   - Xcode command line tools
#   - Security certificate installed (if using --sign)

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
QUICK_MODE="${1:-}"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_section() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

log_info() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

# Parse command line arguments
ENABLE_SIGNING=0
DMG_ONLY=0

for arg in "$@"; do
    case "$arg" in
        --sign)
            ENABLE_SIGNING=1
            ;;
        --dmg-only)
            DMG_ONLY=1
            ;;
        --quick)
            QUICK_MODE=1
            ;;
    esac
done

log_section "Beta Deployment Tool - Words of the Dead"

if [ $DMG_ONLY -eq 1 ]; then
    echo "📦 DMG-only mode (skipping build and testing)"
else
    # Phase 1: Clean Build
    log_section "Phase 1: Building Application"
    
    echo "Building for arm64 and x86_64..."
    WOTD_NO_OPEN=1 ./WordsOfTheDead/build.sh > /dev/null
    
    if [ -d "$ROOT/build/WordsOfTheDead.app" ]; then
        log_info "Build successful"
        ARCH=$(lipo -info "$ROOT/build/WordsOfTheDead.app/Contents/MacOS/WordsOfTheDead" | grep -oE "arm64|x86_64" | sort | uniq | tr '\n' ' ')
        echo "   Architecture: $ARCH"
    else
        log_error "Build failed"
        exit 1
    fi

    # Phase 2: Quick Verification
    log_section "Phase 2: Verifying Build"
    
    echo "Checking app structure..."
    if [ ! -f "$ROOT/build/WordsOfTheDead.app/Contents/MacOS/WordsOfTheDead" ]; then
        log_error "Executable not found"
        exit 1
    fi
    log_info "Executable found"
    
    if [ ! -f "$ROOT/build/WordsOfTheDead.app/Contents/Resources/AppIcon.icns" ]; then
        log_error "App icon not found"
        exit 1
    fi
    log_info "App icon present"
    
    echo "Version in Info.plist:"
    grep "CFBundleShortVersionString" "$ROOT/build/WordsOfTheDead.app/Contents/Info.plist" | grep -oE "1\.0\.0-beta\.[0-9]+" || echo "   (check manually)"

    # Phase 3: Optional - Manual Testing
    if [ "$QUICK_MODE" != "1" ]; then
        log_section "Phase 3: Manual Smoke Test"
        
        read -p "Launch app for manual testing? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Opening app... (close when done testing)"
            open "$ROOT/build/WordsOfTheDead.app"
            
            read -p "Testing complete? (y/n) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_error "Testing cancelled by user"
                exit 1
            fi
        fi
    fi

    # Phase 4: Code Signing (optional)
    if [ $ENABLE_SIGNING -eq 1 ]; then
        log_section "Phase 4: Code Signing"
        
        CERT_ID=$(security find-identity -v -p codesigning | grep "Developer ID" | head -1 | awk '{print $2}' || true)
        
        if [ -n "$CERT_ID" ]; then
            echo "Signing with certificate: $CERT_ID"
            SIGN_FOR_DISTRIBUTION=1 "$ROOT/WordsOfTheDead/build.sh" > /dev/null 2>&1 || {
                log_warn "Code signing step had issues (continuing anyway)"
            }
            log_info "Code signing complete"
        else
            log_warn "No Developer ID certificate found"
            echo "To enable code signing:"
            echo "  1. Get a certificate from Apple Developer"
            echo "  2. Import to Keychain"
            echo "  3. Run: SIGN_FOR_DISTRIBUTION=1 ./tools/deploy-beta.sh"
        fi
    fi
fi

# Phase 5: Create Distribution Package
log_section "Phase 5: Creating Distribution Package"

# Create DMG
echo "Creating DMG installer..."
chmod +x "$ROOT/tools/create-dmg.sh"
"$ROOT/tools/create-dmg.sh"

# Create ZIP package
echo "Creating ZIP package..."
mkdir -p "$ROOT/deploy/beta-1.0.0"
rm -rf "$ROOT/deploy/beta-1.0.0/"*

cp -r "$ROOT/build/WordsOfTheDead.app" "$ROOT/deploy/beta-1.0.0/"
cp "$ROOT/notes/BETA_RELEASE_NOTES.md" "$ROOT/deploy/beta-1.0.0/"

cd "$ROOT/deploy"
ditto -c -k --sequesterRsrc --keepParent beta-1.0.0 WordsOfTheDead-beta-1.0.0.zip 2>/dev/null || \
    zip -r -q WordsOfTheDead-beta-1.0.0.zip beta-1.0.0/
cd "$ROOT"

log_info "ZIP package created"

# Summary
log_section "Deployment Summary"

DMG_SIZE=$(du -h "$ROOT/WordsOfTheDead-1.0.0-beta.1.dmg" 2>/dev/null | cut -f1 || echo "N/A")
ZIP_SIZE=$(du -h "$ROOT/deploy/WordsOfTheDead-beta-1.0.0.zip" 2>/dev/null | cut -f1 || echo "N/A")

echo "📦 Distribution Packages Ready:"
echo "   ZIP:   $ROOT/deploy/WordsOfTheDead-beta-1.0.0.zip ($ZIP_SIZE)"
echo "   DMG:   $ROOT/WordsOfTheDead-1.0.0-beta.1.dmg ($DMG_SIZE)"
echo ""
echo "📝 Documentation:"
echo "   Release Notes: $ROOT/notes/BETA_RELEASE_NOTES.md"
echo "   Deployment Guide: $ROOT/notes/BETA_DEPLOYMENT_GUIDE.md"
echo ""
echo "🚀 Next Steps:"
echo "   1. Review deployment checklist: $ROOT/notes/BETA_DEPLOYMENT_CHECKLIST.md"
echo "   2. Choose distribution method (email/drive/TestFlight)"
echo "   3. Prepare tester list (5-15 people recommended)"
echo "   4. Send packages to testers with release notes"
echo "   5. Set up feedback form: https://forms.google.com"
echo ""
echo "📧 Email Template: See BETA_DEPLOYMENT_GUIDE.md Phase 4.4"
echo ""
log_info "Beta deployment package ready for distribution!"
