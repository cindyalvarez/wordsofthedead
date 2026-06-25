# QA Testing Plan for Words of the Dead

## Prerequisites
- Build the app fresh: `WOTD_NO_OPEN=1 ./WordsOfTheDead/build.sh`
- Enable verbose logging: `export WOTD_VERBOSE=1` or run with `--qa` flag
- Check logs in: `~/Library/Application Support/WordsOfTheDead/logs/wotd.log`

---

## Functional Tests

### New Player Onboarding
- [ ] Launch app → "Select Player" screen appears
- [ ] Enter valid player name (e.g., "Alice") → Create Player button works
- [ ] Player appears in roster
- [ ] Clicking player → Game starts at Level 1
- [ ] Verify player name displayed in HUD

### Game Loop (Single Run)
- [ ] Level 1 → read word definition → answer correctly
- [ ] Score increases, combo multiplier updates
- [ ] Answer wrong → lose 1 life (if multiple lives enabled)
- [ ] Reach game over (0 lives or level progression stops)
- [ ] End-of-run summary shows: correct, missed, newly mastered, best streak
- [ ] Stats recorded: check `~/Library/Application Support/WordsOfTheDead/players/*/learning_profile.json`

### Player Persistence
- [ ] Play a game, record score and level reached
- [ ] Close app completely (force quit if needed)
- [ ] Relaunch app → "Continue as [name]" appears
- [ ] Click continue → resume at same level with same score
- [ ] Verify learning profile unchanged

### Multi-Player
- [ ] Create Player 1, play 3 levels, close
- [ ] Create Player 2, play 2 levels, close
- [ ] Relaunch → Select Player 1 → verify correct level/progress
- [ ] Switch to Player 2 → verify separate progress
- [ ] Verify `players.json` has both players with unique IDs

### Daily Streak Tracking
- [ ] Play enough words to hit daily goal (20 words) → "Goal met: 1 day" shows
- [ ] Play next day (or mock system time) → play 20 words → "Streak: 2 days" shows
- [ ] Close app, relaunch → streak persists
- [ ] Verify `daily_goal.json` contains entries for each day

### Background Images
- [ ] Level 1 → background image loads and displays
- [ ] Level 5, 10, 15, 20 → different backgrounds for multiples-of-5 (sf- images)
- [ ] High level (50, 100) → background still shows (or falls back to black if exhausted)
- [ ] Verify 72 images in `build/WordsOfTheDead.app/Contents/Resources/backgrounds/`

---

## Edge Cases

### Player Name Validation
- [ ] Empty name → error/sanitization
- [ ] 65+ character name → truncated to 64 or error
- [ ] Name with only special characters → sanitized to "player" or rejected
- [ ] Name with unicode (emojis) → sanitized or rejected
- [ ] Duplicate player names (different case) → treated as same player

### Data Loss & Recovery
- [ ] Manually delete `players.json` → app handles gracefully, new roster created
- [ ] Corrupt `learning_profile.json` (replace with invalid JSON) → app loads backup or empty
- [ ] Corrupt `daily_goal.json` → streak still trackable, backup restored if available
- [ ] Verify backup files created in `~/Library/Application Support/WordsOfTheDead/players/*/backups/`

### Timezone & System Time Changes
- [ ] Set system time forward 1 day → daily goal reset detected
- [ ] Set system time back 1 day → streak logic doesn't double-count
- [ ] Set system time to different timezone → daily goal boundary unchanged

### Long Sessions
- [ ] Play 50+ levels continuously → no memory leaks, no lag
- [ ] Verify FPS stays above 30 (if FPS monitor enabled)
- [ ] Check memory usage doesn't grow unbounded

### Missing Resources
- [ ] Delete a background image from app bundle → graceful fallback (black background)
- [ ] Corrupt vocab.json → app shows error or loads last-known-good backup
- [ ] Missing `fun_definitions.json` → definitions still show or default text

---

## Performance Tests

### Startup Time
- [ ] Cold launch (app not in memory) → should show window within 2 seconds
- [ ] Warm launch (app in memory) → within 1 second
- [ ] Player select screen → responsive (no lag when rendering player list)

### Game Loop Performance
- [ ] Level 1: FPS ≥ 30 (smooth gameplay)
- [ ] Level 50: FPS ≥ 30 (scaling handled)
- [ ] Level 100+: FPS ≥ 30 or graceful slowdown warning
- [ ] No jank when spawning zombies
- [ ] Reveal animation smooth (3-second reveal)

### Save/Load Times
- [ ] Save learning profile: < 500ms (should be imperceptible)
- [ ] Save player roster: < 500ms
- [ ] Load on startup: < 1 second

---

## Data Integrity Tests

### Backup Creation
- [ ] After each save, verify backup file created in `backups/` subdirectory
- [ ] Backup naming: `learning_profile_YYYY-MM-DD_N.json`
- [ ] Latest backup can be decoded successfully (test manually)
- [ ] Multiple backups per day (if saving multiple times): counter increments

### Recovery from Corruption
- [ ] Manually corrupt `learning_profile.json` (remove closing brace)
- [ ] Relaunch app → automatic recovery from backup
- [ ] Log shows "Recovered from backup: learning_profile_YYYY-MM-DD_0.json"
- [ ] Player progress intact (verified against backup)

### Logging & Diagnostics
- [ ] Run with `export WOTD_VERBOSE=1`
- [ ] Check `~/Library/Application Support/WordsOfTheDead/logs/wotd.log` exists
- [ ] Log contains entries for: saves, loads, migrations, errors
- [ ] Each log line has timestamp and category: `[2025-06-23T08:15:00Z] [save] Saved players.json`

---

## QA Mode Testing (`--qa` flag)

```bash
open build/WordsOfTheDead.app --args --qa
```

- [ ] QA banner visible (if implemented)
- [ ] Verbose logging enabled (check stdout)
- [ ] Special commands available (debug features)
- [ ] FPS counter visible (if implemented)
- [ ] Can skip levels or jump to high levels (if debug feature)

---

## Deployment Readiness

### Code Signing
- [ ] App bundle code signed with valid developer certificate
- [ ] `codesign -v` reports "valid on disk"
- [ ] No "damaged" or "can't verify" warnings on launch

### Universal Binary
- [ ] `lipo -info build/WordsOfTheDead.app/Contents/MacOS/WordsOfTheDead`
- [ ] Output shows: `Architectures in the fat file: x86_64 arm64`
- [ ] Test on both Intel and Apple Silicon Macs (if available)

### Platform Compatibility
- [ ] macOS 13.0 Ventura: app launches and runs
- [ ] macOS 14.x Sonoma: app launches and runs
- [ ] macOS 15.x Sequoia: app launches and runs
- [ ] Older macOS (12.x): graceful error if not supported

### First-Run Experience
- [ ] Fresh install (no app support dir) → player creation flow works
- [ ] Legacy migration (if applicable) → old progress claimed by first player

---

## Regression Tests (Run After Each Build)

Run this minimal set before shipping:
1. [ ] Functional test: New player → play 1 game → close → relaunch → same progress
2. [ ] Multi-player: Switch between 2 players, verify separate progress
3. [ ] Streak: Hit daily goal, check persistence
4. [ ] Backgrounds: Level 1, 5, 10 show different images
5. [ ] Backups: Corrupt a JSON file, verify recovery

---

## Bugs to Watch For

- **Streak double-counting** on timezone changes (check `DailyGoalTracker.currentStreak`)
- **Memory leaks** in `GameEngine.zombies` array (verify cleanup on game over)
- **Player name collision** when case/punctuation differs (check slug logic)
- **Backup proliferation** (verify daily limit enforced)
- **FPS drops** at levels 50+ (profile memory and CPU)

---

## Sign-Off Checklist

- [ ] All functional tests pass
- [ ] No critical data loss in any edge case
- [ ] Backups created and recovery works
- [ ] Logging functional and clean
- [ ] Startup time acceptable (< 2s cold, < 1s warm)
- [ ] No memory leaks in 1-hour session
- [ ] Player names sanitized correctly
- [ ] Ready for distribution

