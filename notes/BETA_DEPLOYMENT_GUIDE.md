# Beta Deployment Walkthrough

**Goal**: Distribute Words of the Dead to beta testers in a professional, secure manner

**Timeline**: 1-2 hours for full setup

## Phase 1: Pre-Deployment Verification (15 min)

### 1.1 Clean Build Verification

First, ensure the app builds cleanly:

```bash
cd ~/vibe/wordsofthedead
WOTD_NO_OPEN=1 ./WordsOfTheDead/build.sh
```

Expected output:
```
==> Done: /Users/cindya/vibe/wordsofthedead/build/WordsOfTheDead.app
```

✅ **Verify**: No errors, no warnings

### 1.2 Test Core Functionality

Quick smoke test:

```bash
# Launch app
open build/WordsOfTheDead.app

# Verify processes
pgrep -lf "WordsOfTheDead"

# Test features (manual):
# 1. Create player
# 2. Play game, complete a few levels
# 3. Check opening screen (streak, challenges, progress)
# 4. Open settings (gear icon)
# 5. Toggle notifications
# 6. Play again and verify metrics update
# 7. Quit cleanly
```

Kill if needed:
```bash
# Find PID
pgrep -f "WordsOfTheDead.app/Contents/MacOS"

# Kill by PID (numeric only)
kill <PID>
```

✅ **Verify**: No crashes, smooth gameplay

### 1.3 Version & Build Numbers

Update version in `Info.plist`:

```bash
# Check current version
cd build/WordsOfTheDead.app/Contents
grep -A2 "CFBundleShortVersionString" Info.plist
```

For beta, use format: `1.0.0-beta.1`

```bash
# If needed, edit Info.plist
# Or add version management to build.sh
```

✅ **Set version** to `1.0.0-beta.1`

## Phase 2: Code Signing & Notarization (30 min)

### 2.1 Check Current Signing Status

```bash
# View signing info
codesign -dv build/WordsOfTheDead.app/Contents/MacOS/WordsOfTheDead

# Expected: ad hoc signature (development only)
# For distribution: need valid certificate
```

### 2.2 Obtain Code Signing Certificate

**Option A: Using your Apple Developer Account** (Recommended for beta)

```bash
# 1. Open Keychain Access
open /Applications/Utilities/Keychain\ Access.app

# 2. Go to: Keychain Access > Certificate Assistant > Request a Certificate
#    - Save as file
#    - Submit to Apple Developer portal
#    - Download certificate
#    - Double-click to install in Keychain

# 3. Verify certificate installed
security find-identity -v -p codesigning

# Should list identity like:
# 1) ABC123... "Developer ID Application: Your Name (ABC123XYZ)"
```

**Option B: Self-Signed (For internal beta only)**

```bash
# Create self-signed certificate
security create-keychain -p password ~/Library/Keychains/WordsOfTheDead.keychain

# Create certificate
security add-generic-password -a WordsOfTheDead -s "WordsOfTheDead-Code-Signing" \
  -p "certificate" ~/Library/Keychains/WordsOfTheDead.keychain
```

### 2.3 Sign the Application

```bash
# Find your certificate ID
CERT_ID=$(security find-identity -v -p codesigning | grep "Developer ID" | awk '{print $2}')

# Sign the app
codesign --deep --force --verify --verbose --sign "$CERT_ID" \
  build/WordsOfTheDead.app

# Verify signing
codesign -dv build/WordsOfTheDead.app/Contents/MacOS/WordsOfTheDead
```

✅ **Verify**: Signed with valid certificate

### 2.4 Apple Notarization (For distribution outside App Store)

Notarization ensures macOS Gatekeeper won't block the app.

**Step 1: Create App-Specific Password**

```bash
# Go to https://appleid.apple.com/account/manage
# -> App-Specific Passwords
# -> Generate new password (copy it)
# Use format: xxxx-xxxx-xxxx-xxxx
```

**Step 2: Notarize the App**

```bash
# First, create a zip of the signed app
cd build
ditto -c -k --sequesterRsrc --keepParent WordsOfTheDead.app WordsOfTheDead.zip

# Submit for notarization
xcrun notarytool submit WordsOfTheDead.zip \
  --apple-id "your-apple-id@icloud.com" \
  --password "xxxx-xxxx-xxxx-xxxx" \
  --team-id "ABC123XYZ" \
  --wait

# Expected output:
# id: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
# status: Accepted
```

**Step 3: Staple Notarization Ticket**

```bash
# Attach notarization to app
xcrun stapler staple build/WordsOfTheDead.app

# Verify
xcrun stapler validate build/WordsOfTheDead.app
```

✅ **Verify**: Notarization accepted, staple successful

### 2.5 Create Signed Build Script

Add to `WordsOfTheDead/build.sh` (after app is built):

```bash
# Code signing (optional, for distribution)
if [ "$SIGN_FOR_DISTRIBUTION" = "1" ]; then
    CERT_ID=$(security find-identity -v -p codesigning | grep "Developer ID" | awk '{print $2}')
    if [ -n "$CERT_ID" ]; then
        echo "==> Signing app with certificate: $CERT_ID"
        codesign --deep --force --verify --verbose --sign "$CERT_ID" \
            "$APP_PATH"
        echo "✓ Signing complete"
    fi
fi
```

Usage:
```bash
SIGN_FOR_DISTRIBUTION=1 ./WordsOfTheDead/build.sh
```

## Phase 3: Create Distribution Package (20 min)

### 3.1 Create DMG (Disk Image) Installer

This gives beta users a professional installer experience:

```bash
# Create script: tools/create-dmg.sh

#!/bin/bash
set -e

APP_NAME="Words of the Dead"
APP_PATH="build/WordsOfTheDead.app"
DMG_NAME="WordsOfTheDead-1.0.0-beta.1.dmg"
TEMP_DIR="/tmp/wotd_dmg_$$"

# Create temporary directory
mkdir -p "$TEMP_DIR"

# Copy app
cp -r "$APP_PATH" "$TEMP_DIR/"

# Create symlink to Applications folder
ln -s /Applications "$TEMP_DIR/Applications"

# Create DMG
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$TEMP_DIR" \
    -ov -format UDZO "$DMG_NAME"

# Cleanup
rm -rf "$TEMP_DIR"

echo "✓ DMG created: $DMG_NAME"
```

Create and use:

```bash
chmod +x tools/create-dmg.sh
./tools/create-dmg.sh
ls -lh WordsOfTheDead-1.0.0-beta.1.dmg
```

### 3.2 Create Release Notes

Create file: `BETA_RELEASE_NOTES.md`

```markdown
# Words of the Dead - Beta 1.0.0

## What's New

### Engagement Features
- ✨ Daily streak tracking with visual feedback
- 📊 Daily goal progress visualization
- 🎯 Rotating daily challenges
- 🔔 Smart notifications (5 PM reminders, milestones)
- ⏰ Customizable quiet hours (default 9 PM - 9 AM)
- ⚙️ Notification settings UI

### Core Game
- Zombie-themed vocabulary learning
- Progressive difficulty levels
- Daily goal tracking
- Word mastery progression
- Beautiful background images

## Known Issues

- [None currently - first beta!]

## How to Report Issues

1. **In-App Diagnostics**: Gear icon → Send Diagnostics Bundle
2. **Email**: Send crash logs and reproduction steps
3. **GitHub Issues**: [link to repo if public]

## System Requirements

- macOS 11.0 or later
- Apple Silicon (M1+) or Intel (x86_64)
- 100 MB disk space

## Installation

1. Download `WordsOfTheDead-1.0.0-beta.1.dmg`
2. Double-click to mount
3. Drag "Words of the Dead" to Applications folder
4. Launch from Applications
5. Grant notification permissions on first launch

## Feedback

We value your feedback! Please test:
- [ ] App launches cleanly
- [ ] Player creation works
- [ ] Games play smoothly
- [ ] Streak displays correctly
- [ ] Notifications work (check quiet hours)
- [ ] Settings persist after restart
- [ ] No crashes during gameplay

Thank you for helping us ship an amazing game!
```

## Phase 4: Setup Beta Distribution (20 min)

### 4.1 Email-Based Distribution

Simple approach for small beta group:

```bash
# Package for email
mkdir -p deploy/beta-1.0.0
cp build/WordsOfTheDead.app deploy/beta-1.0.0/
cp BETA_RELEASE_NOTES.md deploy/beta-1.0.0/
cd deploy
zip -r WordsOfTheDead-beta-1.0.0.zip beta-1.0.0/
```

Send to testers:
- Attachment: `WordsOfTheDead-beta-1.0.0.zip`
- Email template (see below)

### 4.2 Google Drive / iCloud Link

For easier updates:

```bash
# Upload to shared folder
# Create shareable link
# Send link to beta testers

# Share link format:
# https://drive.google.com/drive/folders/[FOLDER_ID]?usp=sharing
```

### 4.3 TestFlight (If Using App Store Connect)

```bash
# Upload IPA to App Store Connect
# Add testers via email
# They receive TestFlight invitation
# One-tap install

# Note: Requires Apple Developer account ($99/year)
```

### 4.4 Email Template for Beta Testers

```markdown
Subject: Words of the Dead - Beta 1.0.0 Available for Testing

Hi [Beta Testers],

Thank you for agreeing to test Words of the Dead! 🎮

**Installation Instructions:**

1. Download attached: WordsOfTheDead-beta-1.0.0.zip
2. Extract the app
3. Drag "Words of the Dead" to your Applications folder
4. Launch from Applications
5. Grant notification permissions on first launch

**What to Test:**

☐ App launches and runs smoothly
☐ Create a new player profile
☐ Complete at least one game session
☐ Check that streak displays on opening screen
☐ Test notification settings (gear icon)
☐ Quit and restart - verify settings persist
☐ Play multiple sessions and track progress

**Known Limitations:**

- First beta release - UI polish to come
- Some edge cases may not be handled

**How to Report Issues:**

1. **Crashes**: Send error logs from ~/Library/Logs/WordsOfTheDead/
2. **Bugs**: Describe steps to reproduce
3. **Suggestions**: General feedback welcome

**Diagnostics Bundle:**
If something breaks, use the in-app Settings → Send Diagnostics Bundle feature to send logs.

**Timeline:**
- Testing period: 1 week
- Feedback deadline: [DATE]
- Public release: [DATE]

Questions? Reply to this email.

Thanks for being part of the launch! 🚀

- Words of the Dead Team
```

## Phase 5: Setup Feedback Collection (15 min)

### 5.1 Create Feedback Form

Use Google Forms:

```
https://forms.gle/[ID]

Questions:
1. Did the app launch successfully? (Yes/No)
2. Any crashes? (Yes/No) → If yes, describe
3. Game performance? (Smooth/Laggy/Unplayable)
4. Engagement features working? (Yes/No)
5. Notifications working as expected? (Yes/No)
6. Any feature requests?
7. Overall rating? (1-5 stars)
```

### 5.2 Create Issues Repository

For tracking bugs:

```bash
# If not already git repo:
git init
git add .
git commit -m "Initial beta release"

# Create GitHub repo (or use internal git)
# Add testers as collaborators
# Use GitHub Issues for bug tracking
```

### 5.3 Setup Logging for Diagnostics

Already implemented! Users can:

```
Settings (gear icon) → Send Diagnostics Bundle
```

This creates ZIP with:
- App logs
- Player count (anonymized)
- System info
- No personal data

## Phase 6: Prepare Deployment Checklist (10 min)

### Pre-Release Checklist

- [ ] Clean build succeeds
- [ ] Smoke test passes
- [ ] Version bumped to `1.0.0-beta.1`
- [ ] Code signed with valid certificate
- [ ] Notarization complete and stapled
- [ ] DMG created successfully
- [ ] Release notes written
- [ ] Feedback form created
- [ ] Distribution method chosen (email/drive/TestFlight)
- [ ] Beta tester list ready
- [ ] Email template prepared
- [ ] Backup of code in git
- [ ] Documentation reviewed

### On-Release Checklist

- [ ] Send email to beta testers
- [ ] Monitor for responses
- [ ] Track reported issues
- [ ] Respond to feedback within 24h
- [ ] Document all issues found
- [ ] Create hotfix plan if needed

### Post-Beta Checklist

- [ ] Collect all feedback
- [ ] Prioritize issues by severity
- [ ] Create bug fix release notes
- [ ] Plan for beta.2 or 1.0 release

## Phase 7: Quick Start - End-to-End (5 min summary)

Here's the complete flow in one go:

```bash
#!/bin/bash

set -e
cd ~/vibe/wordsofthedead

echo "=== Beta Deployment ==="

# 1. Build
echo "1. Building app..."
WOTD_NO_OPEN=1 ./WordsOfTheDead/build.sh

# 2. Test
echo "2. Testing core functionality..."
# Manual test: open build/WordsOfTheDead.app

# 3. Sign (if certificate available)
echo "3. Signing app..."
CERT_ID=$(security find-identity -v -p codesigning | grep "Developer ID" | head -1 | awk '{print $2}')
if [ -n "$CERT_ID" ]; then
    codesign --deep --force --verify --verbose --sign "$CERT_ID" build/WordsOfTheDead.app
fi

# 4. Create DMG
echo "4. Creating DMG installer..."
./tools/create-dmg.sh

# 5. Create deployment package
echo "5. Packaging for distribution..."
mkdir -p deploy/beta-1.0.0
cp build/WordsOfTheDead.app deploy/beta-1.0.0/
cp BETA_RELEASE_NOTES.md deploy/beta-1.0.0/
cd deploy
zip -r WordsOfTheDead-beta-1.0.0.zip beta-1.0.0/
cd ..

echo "✅ Beta package ready: deploy/WordsOfTheDead-beta-1.0.0.zip"
echo "✅ DMG ready: WordsOfTheDead-1.0.0-beta.1.dmg"
echo "📧 Send to beta testers with email template"
```

Save as `tools/deploy-beta.sh`:

```bash
chmod +x tools/deploy-beta.sh
./tools/deploy-beta.sh
```

## Quick Reference: Common Issues

| Issue | Solution |
|-------|----------|
| Code signing fails | Check certificate in Keychain, or use ad-hoc signing for internal beta |
| Notarization rejected | Check app requirements, enable hardened runtime, re-sign |
| DMG won't mount | Use different `hdiutil` format (UDZO → UDRW) |
| Testers can't open app | Needs notarization or ad-hoc signature, check Gatekeeper settings |
| Crash reports missing | Check ~/Library/Logs/WordsOfTheDead/ for logs |

## Next Steps (After Beta)

1. **Collect Feedback** - 1 week of testing
2. **Fix Critical Issues** - Create beta.2 if needed
3. **Prepare 1.0 Release** - Polish for public release
4. **Set Up Auto-Updates** - Implement version checking
5. **Launch Publicly** - GitHub releases, website, etc.

---

**Deployment Readiness**: ✅ Ready to proceed

**Estimated Time**: 1-2 hours for full setup
**Estimated Testers**: 5-20 beta users recommended
**Testing Period**: 1 week

Next: Choose your distribution method and let's send it out!
