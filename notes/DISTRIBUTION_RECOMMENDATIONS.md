# Words of the Dead — Distribution & Engagement Recommendations

## Current State ✅
- ✅ **Game saves**: Player roster, learning profile, daily goals persisted to `~/Library/Application Support/WordsOfTheDead/`
- ✅ **Level progression**: Lives-based system with level scaling
- ✅ **Word mastery**: Spaced repetition scheduler with `MasteryStage` levels
- ✅ **Daily tracking**: 20-word daily goal with streak counter
- ✅ **End-of-run summary**: Tracks correct, missed, newly mastered, best streak
- ✅ **Scoring system**: Combo multiplier feedback
- ✅ **Multi-player support**: Player roster with legacy progress migration

---

## 🐛 Bug Prevention & Stability

### High Priority
1. **Data Corruption Edge Cases**
   - [ ] Add file locking during save operations (prevent crashes mid-write)
   - [ ] Create automatic daily backup of player data to timestamped files
   - [ ] Implement version detection + migration path for saved data format changes
   - [ ] Add error recovery: if a JSON file is malformed, revert to last known good backup instead of losing data

2. **Save State Testing**
   - [ ] Test each player-select → levelintro → gameOver → save → relaunch cycle
   - [ ] Verify streak logic doesn't break on timezone changes or system time travel
   - [ ] Test legacy migration (pre-player progress claim) edge cases: multiple roster resets, new players

3. **Memory/Performance**
   - [ ] Profile memory usage over long sessions (check for leaks in zombie spawning loop)
   - [ ] Stress test with 50+ levels to verify no lag at high levels
   - [ ] Add framerate monitoring in QA mode (log if FPS drops below 30)

4. **Input Validation**
   - [ ] Sanitize player names (prevent empty names, extreme lengths)
   - [ ] Verify vocabulary JSON can't be corrupted by malformed data files
   - [ ] Add graceful fallback if background images fail to load (shouldn't crash)

### Medium Priority
5. **Logging & Diagnostics**
   - [ ] Add optional verbose logging to QA mode (write to file in app support dir)
   - [ ] Log first-run detection vs subsequent launches
   - [ ] Log when saves fail, when data migrations occur
   - [ ] Export diagnostics bundle for debugging user issues

6. **Platform-Specific**
   - [ ] Test on older macOS versions (13.0 is the target; verify nothing breaks)
   - [ ] Test universal binary (both ARM64 and x86_64) on real hardware if possible
   - [ ] Verify app code signing won't cause issues for end users

---

## 📊 Measuring Progress (Word Mastery)

### Current Implementation
- Spaced repetition scheduler in `WordScheduler` with `MasteryStage` enum

### Recommended Enhancements
7. **Mastery Dashboard View**
   - [ ] Show overview screen: total words, mastered, in-progress, not-yet-seen
   - [ ] Display mastery stages pie chart (New, Reviewing, Familiar, Strong, Mastered)
   - [ ] List recently mastered words (last 10 with dates)
   - [ ] Show words "at risk" (haven't reviewed in >3 days, about to forget)

8. **Per-Word Statistics**
   - [ ] Track times seen, times correct, times missed per word
   - [ ] Show graph of mastery progression over time
   - [ ] Highlight words the player struggles with (lowest accuracy)
   - [ ] Show estimated time until mastery for each word

9. **Learning Curve Metrics**
   - [ ] Words mastered per week (rolling 7-day average)
   - [ ] Accuracy trend (%), days this week, lifetime
   - [ ] Estimated time to master full vocabulary at current pace
   - [ ] Compare to initial baseline

---

## ⏰ Daily Reminders & Return Engagement

### Current Implementation
- Daily goal (20 words) with streak counter

### Recommended Additions

10. **Streak Visualization**
    - [ ] Make the current streak prominent on main screen (big number)
    - [ ] Show "Days until next milestone" (every 7, 14, 30 days)
    - [ ] Add visual reward animation when hitting 7, 14, 30-day streaks
    - [ ] Show "Break-in streak" counter if streak was broken recently (motivation to rebuild)

11. **Notifications & Reminders** (requires macOS notification permissions)
    - [ ] Optional: "You haven't studied today — come back!" notification at 5 PM
    - [ ] Daily streak milestone notifications ("28-day streak! 🔥")
    - [ ] Weekly summary: words learned, accuracy %, streak status
    - [ ] Configurable quiet hours (no notifications 9 PM–9 AM)

12. **Opening Screen Engagement**
    - [ ] Show streaks, daily progress, and any newly mastered words from previous session
    - [ ] Display "Today's challenge" teaser (e.g., "10 new words today")
    - [ ] Add motivational message based on streak length (1 day: "Keep it up!", 7 days: "On fire! 🔥")

---

## 🎮 Gameplay & Engagement

### High Priority
13. **Boss Levels** (seems partially implemented)
    - [ ] Define boss level rules: every 10/25/50 levels? Triple zombies? Time pressure?
    - [ ] Add boss-specific UI (red background, dramatic text)
    - [ ] Boss rewards: extra points, rare achievement badges

14. **Difficulty Curve**
    - [ ] Track player accuracy by level and auto-adjust difficulty
    - [ ] If accuracy > 90%, increase zombie speed or spawn rate
    - [ ] If accuracy < 60%, add hint button or slightly slow zombies
    - [ ] Warn user before first difficulty increase

15. **End-of-Run Screen**
    - [ ] Current summary (correct, missed, newly mastered, best streak) ✅ exists
    - [ ] Add session stats: accuracy %, new words seen, time played
    - [ ] Show XP/rewards earned
    - [ ] Display next milestone (e.g., "10 more words to next level milestone")

### Medium Priority
16. **Power-ups & Special Events**
    - [ ] Random "power-ups" during gameplay (slow time, freeze zombies, freeze timer)
    - [ ] Weekly challenges: "Get 50+ accuracy" or "Master 5 words today"
    - [ ] Achievement badges (e.g., "Perfect Run: 100% accuracy", "Speed Demon: 5 levels in one session")

17. **Pause & Resume** (comment mentions "suggestion #17")
    - [ ] Verify pause system works correctly (save/restore game state)
    - [ ] Test pause doesn't break score/combo/streak counting

18. **Audio (future enhancement)**
    - [ ] Optional sound effects for zombie spawn, correct/wrong answer, level complete
    - [ ] Background music (toggleable)
    - [ ] Level-up fanfare

---

## 📦 Distribution & Installation

19. **Code Signing & Notarization**
    - [ ] Sign app with valid Apple Developer certificate before distributing
    - [ ] Notarize with Apple (required for Monterey+; prevents "can't verify developer" warning)
    - [ ] Create DMG installer with background image and drag-to-Applications shortcut
    - [ ] Test installation on clean machine (not your dev machine)

20. **First-Run Experience**
    - [ ] Detect first run and show welcome/tutorial
    - [ ] Explain what "Mastery" means
    - [ ] Quick demo: show 1–2 levels and explain daily goal
    - [ ] Offer to import legacy data if exists

21. **Settings & Preferences**
    - [ ] Create Settings screen accessible from main menu
    - [ ] Allow toggling daily notifications on/off
    - [ ] Allow changing daily goal (default 20)
    - [ ] Allow resetting player roster (with confirmation)
    - [ ] Show version number and build date

22. **Accessibility**
    - [ ] Ensure all text has sufficient contrast
    - [ ] Support keyboard navigation (Tab, Enter, Arrow keys)
    - [ ] Test with macOS VoiceOver (screen reader)
    - [ ] Allow font size scaling in settings

---

## 🧪 QA & Testing Checklist

### Functional Testing
- [ ] Test each player flow: new player → play → save → resume
- [ ] Multi-player: create 2 players, switch between them, verify separate progress
- [ ] Daily goal: play 19 words, verify streak not met; play 20, verify marked as met
- [ ] Levels 1–10, 25, 50, 100+: verify scaling, no infinite loops, proper zombie behavior
- [ ] Game over: verify lives system, score calculation, final stats screen
- [ ] Background images: all 72 load correctly, no missing images at any level

### Edge Cases
- [ ] Close app mid-game → relaunch → verify game saved correctly
- [ ] Delete player while another is active → verify roster updates
- [ ] Run out of vocabulary words (if vocabulary < zombie spawns)
- [ ] Timezone/DST changes → verify streak logic holds
- [ ] Long sessions (2+ hours) → check for memory leaks

### Performance
- [ ] Cold start from Dock (first launch)
- [ ] Player select screen responsiveness
- [ ] Game loop FPS at high levels
- [ ] Save/load time < 500ms

### Deployment
- [ ] Verify app bundle contents (all resources present)
- [ ] Test on both M1 (ARM64) and Intel (x86_64) Macs if possible
- [ ] Verify app doesn't require root or sudo
- [ ] Check macOS version compatibility (test on 13.0+)

---

## 📝 Optional "Nice to Have" Features

23. **Statistics & Analytics (future)**
    - [ ] Export learning data as CSV
    - [ ] Sync progress across devices (cloud backup)
    - [ ] Leaderboard (local: fastest to master vocab)

24. **Content Expansion**
    - [ ] Support multiple vocabulary lists (e.g., Spanish SAT vocab, medical terms)
    - [ ] User-submitted word lists
    - [ ] Difficulty levels (kids vs. adults)

25. **Community Features**
    - [ ] Share achievements ("I mastered 200 words! 🧟")
    - [ ] Optional multiplayer mode (local network)
    - [ ] Discord/Slack integration for streaks

---

## 🚀 Phased Release Plan

**Phase 1 (MVP):** Focus on bugs, saves, and first-run experience
- [ ] Complete items 1–6, 19–22

**Phase 2 (1.0 Release):** Engagement features
- [ ] Complete items 7–18

**Phase 3 (Post-1.0):** Polish & expansion
- [ ] Complete items 23–25

---

## Implementation Notes

- **Save data location**: Already using `~/Library/Application Support/WordsOfTheDead/` ✅
- **Persisted files to check**: `players.json`, `learning_profile/*.json`, `daily_goal.json`, `background_assignments.json`
- **Key classes to review**: `GameEngine`, `WordScheduler`, `DailyGoalTracker`, `PlayerStore`, `LearningStore`
- **UI views to enhance**: Game start screen, end-of-run summary, new "Dashboard" view for mastery stats
