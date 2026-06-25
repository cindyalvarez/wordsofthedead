# Quick Testing Guide - Words of the Dead v1.0.0-beta.1

## Installation & First Run

### Option A: From DMG (Distribution Test)
```bash
# 1. Mount DMG
open ~/vibe/wordsofthedead/WordsOfTheDead-1.0.0-beta.1.dmg

# 2. Drag WordsOfTheDead.app to Applications
# 3. Launch from Applications folder
```

### Option B: From Built App (Development Test)
```bash
cd ~/vibe/wordsofthedead
WOTD_NO_OPEN=1 ./WordsOfTheDead/build.sh
open build/WordsOfTheDead.app
```

---

## Test Scenarios

### 1. ✅ New Player Creation (CRITICAL TEST)
**Objective:** Verify no hang/beachball occurs

**Steps:**
1. Launch app
2. Click "New Player"
3. Enter name: "Tester"
4. Click "Create"

**Expected Result:**
- ✅ No hang or beachball
- ✅ Opening screen displays within 2-3 seconds
- ✅ "Last Session Stats" and "Share Progress" buttons visible

**If Hang Occurs:**
- Note the exact step where it freezes
- Check Console.app for crash logs
- Report with system details (Mac model, macOS version)

---

### 2. ✅ Share Progress Feature
**Objective:** Verify new Share Progress button works correctly

**Steps:**
1. Create or select a player
2. Play a few levels to generate stats
3. Return to opening screen
4. Locate "Share Progress" button (between stats and play button)
5. Click button
6. Verify stats display:
   - "Levels Played Today: X"
   - "Words Mastered Today: X"
   - "Total Words Mastered: X"
7. Click "Share Progress" in stats display
8. Verify email input box appears
9. Confirm default email is "cindy.alvarez@gmail.com"
10. Enter custom email to test editability
11. Click "Done"

**Expected Result:**
- ✅ Stats display correctly
- ✅ Email input appears on click
- ✅ Default email is cindy.alvarez@gmail.com
- ✅ Can edit email to custom value
- ✅ Share completes without errors

---

### 3. ✅ Notification Settings
**Objective:** Verify notification permissions work correctly

**Steps:**
1. Open app
2. Access Settings (or Preferences)
3. Navigate to Notifications section
4. Toggle notifications on
5. System dialog should appear requesting permission

**Expected Result:**
- ✅ Permission dialog appears (NOT during app startup)
- ✅ Can grant or deny permissions
- ✅ Settings respected after toggle

---

### 4. ✅ Gameplay Flow
**Objective:** Verify core gameplay works with new feature

**Steps:**
1. Create new player
2. Play through several levels
3. Return to opening screen multiple times
4. Exit and relaunch app
5. Verify saved progress

**Expected Result:**
- ✅ Levels play smoothly
- ✅ Progress saved correctly
- ✅ Stats accumulate correctly

---

### 5. ✅ App Quit
**Objective:** Verify clean shutdown

**Steps:**
1. Run the app for 30+ seconds
2. Close app window (Cmd+Q or File → Quit)
3. Relaunch app

**Expected Result:**
- ✅ App quits cleanly (no crash)
- ✅ All progress saved
- ✅ App relaunches successfully

---

## Issue Reporting Template

If you encounter issues, please provide:

```
**Issue:** [Brief description]
**Severity:** [Critical/High/Medium/Low]
**Steps to Reproduce:**
1. [First step]
2. [Second step]
3. [etc.]

**Expected Behavior:** [What should happen]
**Actual Behavior:** [What actually happened]

**System Details:**
- Mac model: [e.g., MacBook Pro M1]
- macOS version: [e.g., 13.2]
- Build version: [1.0.0-beta.1]
- Installation method: [DMG/Built locally]

**Console Output:** [Any error messages from Console.app]
**Screenshots/Video:** [If applicable]
```

---

## Performance Expectations

### App Startup
- **Cold start:** 2-3 seconds
- **After new player creation:** No hang (should complete in <2 seconds)

### Gameplay
- **Level load:** <1 second
- **Word reveal:** Immediate
- **Navigation:** Responsive (no freezing)

### UI Responsiveness
- **Button clicks:** Immediate response
- **Screen transitions:** Smooth (<200ms)
- **Settings changes:** Instant update

---

## Troubleshooting

### App Won't Launch
**Solution:**
```bash
cd ~/vibe/wordsofthedead
WOTD_NO_OPEN=1 ./WordsOfTheDead/build.sh
```

### App Hangs on Startup
**Check:**
1. Is it NotificationManager hang? (Now FIXED)
   - Should NOT hang anymore
   - If it does, report immediately
2. Check Console.app for errors
   - Cmd+Space → Console
   - Look for WordsOfTheDead errors

### Stats Not Showing
**Solution:**
1. Quit app completely
2. Play at least 1 full level
3. Return to opening screen
4. Stats should appear

### Email Input Not Working
**Solution:**
1. Click "Share Progress" button
2. If stats don't appear, verify you've played levels today
3. Email input should appear in stats card
4. Clear default email and type custom value

---

## Quick Commands

```bash
# Build and run
cd ~/vibe/wordsofthedead && WOTD_NO_OPEN=1 ./WordsOfTheDead/build.sh && open build/WordsOfTheDead.app

# Create DMG for testing
./tools/create-dmg.sh

# View console output
log stream --predicate 'process == "WordsOfTheDead"'

# Kill running app
pkill -9 WordsOfTheDead

# Check if app is running
pgrep -x WordsOfTheDead && echo "Running" || echo "Not running"
```

---

## Feature Checklist

- [ ] App launches without hang
- [ ] New player creation works
- [ ] Share Progress button visible on opening screen
- [ ] Stats display correctly
- [ ] Email input appears on click
- [ ] Default email is cindy.alvarez@gmail.com
- [ ] Custom email can be entered
- [ ] Notification settings accessible
- [ ] Full gameplay flow works
- [ ] App quits cleanly
- [ ] Progress persists across restarts

---

## Build Information

- **Version:** 1.0.0-beta.1
- **Architectures:** arm64, x86_64 (Universal Binary)
- **Code Signing:** Not signed (development build)
- **Distribution:** Available as DMG and ZIP
- **Last Updated:** [Current session]

**Ready for beta distribution!** ✅
