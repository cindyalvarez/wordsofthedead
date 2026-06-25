# Bug Prevention & QA Implementation Summary

## ✅ COMPLETED (6/14 items)

### 1. **File Locking During Save Operations** ✅
**File**: `FileUtilities.swift` (new)
- Implements atomic writes using temp file + POSIX rename pattern
- Prevents corruption if process crashes mid-write
- `writeAtomically()` function used by all save stores

### 2. **Automatic Daily Backups** ✅
**File**: `FileUtilities.swift`
- `createBackupIfNeeded()` creates timestamped backups before each save
- Backups stored in `backups/` subdirectory next to original file
- Format: `filename_YYYY-MM-DD_N.json` (N increments if multiple saves per day)
- Example: `~/Library/Application Support/WordsOfTheDead/players/<id>/backups/learning_profile_2025-06-23_0.json`

### 3. **Error Recovery for Malformed JSON** ✅
**File**: `FileUtilities.swift`
- `loadWithRecovery<T>()` generic function attempts main file, then falls back to latest backup
- Restores backup to main file automatically on successful recovery
- Logs recovery action with file names
- Integrated into: `PlayerStore.load()`, `LearningStore.load()`, `DailyGoalStore.load()`

### 4. **Logging Infrastructure** ✅
**File**: `FileUtilities.swift`
- `log()` function writes to `~/Library/Application Support/WordsOfTheDead/logs/wotd.log`
- Enabled in QA mode (`--qa` flag) or via `WOTD_VERBOSE=1` environment variable
- Also prints to stdout in QA mode for immediate feedback
- Format: `[2025-06-23T08:15:00Z] [category] message`
- Categories: `save`, `load`, `backup`, `recovery`, `validation`, `diagnostics`

### 5. **Player Name Validation** ✅
**File**: `InputValidation.swift` (new)
- `sanitizePlayerName()` function validates and cleans player names
- Constraints: 1–64 characters, alphanumeric + spaces, hyphens, apostrophes
- Removes invalid characters and logs sanitization
- `isValidPlayerName()` for pre-check without modification

### 6. **QA Testing Guide** ✅
**File**: `QA_TESTING_GUIDE.md` (in session files)
- Comprehensive test plan covering:
  - Functional tests (onboarding, game loop, persistence, multi-player, streaks, backgrounds)
  - Edge cases (name validation, data loss, timezone changes, long sessions)
  - Performance tests (startup, game loop FPS, save/load times)
  - Data integrity (backups, recovery, logging)
  - Regression suite
  - Sign-off checklist

---

## 🔄 IN PROGRESS (0 items)

---

## ⏳ REMAINING (8/14 items)

### 7. **Version Detection + Migration** ⏳
- [ ] Add `schemaVersion` field to saved JSON files
- [ ] Implement version check on load, dispatch migration handlers
- [ ] Example: if v1→v2, update field names/structure

### 8. **Input Validation: Vocabulary JSON** ⏳
- [ ] Validate vocabulary.json structure on startup
- [ ] Catch format errors early before gameplay
- [ ] Example: ensure each word has `word`, `definition`, `funDefinition` fields

### 9. **Input Validation: Graceful Image Load Failure** ⏳
- [ ] Catch image load errors in `BackgroundCatalog.image()`
- [ ] Log missing images, don't crash
- [ ] Already falls back to black, but should log the error

### 10. **Memory Profiling for Leaks** ⏳
- [ ] Profile `GameEngine` during long sessions
- [ ] Check `zombies` array cleanup on game over
- [ ] Verify `generator` and `scheduler` aren't accumulating state
- [ ] Use Instruments (Xcode) or add memory tracking in QA mode

### 11. **Stress Testing High Levels** ⏳
- [ ] Play levels 1–10, 25, 50, 100+ without lag
- [ ] Document FPS, spawn rates, difficulty curve
- [ ] Add QA command to jump to arbitrary level for testing

### 12. **FPS Monitoring in QA Mode** ⏳
- [ ] Add frame counter in QA mode (if implementing custom drawing)
- [ ] Log if FPS drops below 30
- [ ] Or use Instruments to measure externally

### 13. **Diagnostics Export Bundle** ⏳
- [ ] `exportDiagnostics()` function partially implemented in FileUtilities
- [ ] Currently creates temp dir with logs, roster, manifest
- [ ] Enhance to create zipped bundle for easy sharing
- [ ] Add menu option in game to export diagnostics

### 14. **Edge Case Testing: Multi-Player, Timezone, Legacy Migration** ⏳
- [ ] Run full edge-case suite from QA_TESTING_GUIDE.md
- [ ] Verify legacy migration doesn't re-trigger for later players
- [ ] Confirm timezone changes don't break streak logic

---

## How to Use the New Features

### Enable Verbose Logging
```bash
# Option 1: Environment variable
export WOTD_VERBOSE=1
open build/WordsOfTheDead.app

# Option 2: QA mode (also enables logging)
open build/WordsOfTheDead.app --args --qa
```

### Check Logs
```bash
tail -f ~/Library/Application Support/WordsOfTheDead/logs/wotd.log
```

### Verify Backups
```bash
ls -la ~/Library/Application Support/WordsOfTheDead/players/*/backups/
```

### Test Backup Recovery
```bash
# Corrupt a JSON file (manually for testing)
echo "{broken" > ~/Library/Application\ Support/WordsOfTheDead/players/*/learning_profile.json

# Relaunch app — it should recover from backup
open build/WordsOfTheDead.app
# Check log: "Recovered from backup: learning_profile_..."
```

---

## Next Steps: Recommended Priority

1. **Version Migration** (7) — foundational for future updates
2. **Vocabulary Validation** (8) — catches startup errors
3. **Graaceful Image Loading** (9) — prevents crashes
4. **Memory Profiling** (10) — ensures stability at scale
5. **FPS Monitoring** (12) — performance visibility
6. **Stress Testing** (11) — complete performance validation
7. **Diagnostics Export** (13) — user support tool
8. **Edge Case Testing** (14) — comprehensive QA run

---

## Files Modified/Created

**New Files:**
- `WordsOfTheDead/Sources/Data/FileUtilities.swift` (286 lines) — atomic saves, backups, recovery, logging
- `WordsOfTheDead/Sources/Data/InputValidation.swift` (48 lines) — player name sanitization
- `QA_TESTING_GUIDE.md` — comprehensive test plan

**Modified Files:**
- `WordsOfTheDead/Sources/Data/PlayerStore.swift` — uses atomic saves + error recovery
- `WordsOfTheDead/Sources/Data/LearningStore.swift` — uses atomic saves + error recovery
- `WordsOfTheDead/Sources/Data/DailyGoalStore.swift` — uses atomic saves + error recovery
- `WordsOfTheDead/Sources/Data/BackgroundStore.swift` — uses atomic saves
- `WordsOfTheDead/build.sh` — added background image check

---

## Testing Verification

Build Status: ✅ Clean, no errors or warnings
```bash
cd /Users/cindya/vibe/wordsofthedead
WOTD_NO_OPEN=1 ./WordsOfTheDead/build.sh
```

Quick Functional Test:
1. Launch app: `open build/WordsOfTheDead.app --args --qa`
2. Create a player, play a game
3. Check logs: `tail ~/Library/Application\ Support/WordsOfTheDead/logs/wotd.log`
4. Verify log shows: saves, loads, backups created

---

## Distribution Readiness

✅ Bug prevention infrastructure in place
✅ Data integrity safeguards (atomic saves, backups, recovery)
✅ Verbose logging for debugging
✅ Comprehensive QA testing guide

⏳ Still needed: Memory profiling, FPS monitoring, edge case testing
⏳ Before shipping: Run full QA test matrix, sign code, notarize

