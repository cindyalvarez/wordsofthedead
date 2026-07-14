# Words of the Dead — Game Design Document

> **Last updated:** July 2026  
> **Purpose:** Living reference for the current design and implementation. Accurate as of the codebase at this date. Detailed enough to recreate the game from scratch.

---

## Table of Contents

1. [Overview](#overview)
2. [Technical Platform](#technical-platform)
3. [Data Files and Content](#data-files-and-content)
4. [Player Profiles and Persistence](#player-profiles-and-persistence)
5. [Opening Cutscene](#opening-cutscene)
6. [Game Start Screen](#game-start-screen)
7. [Level Intro Screen](#level-intro-screen)
8. [Playfield Layout](#playfield-layout)
9. [Visual Design: Zombie Art](#visual-design-zombie-art)
10. [Level Types (Challenge Modes)](#level-types-challenge-modes)
11. [Game Mechanics](#game-mechanics)
12. [Scoring and Combos](#scoring-and-combos)
13. [Spaced-Repetition Learning System](#spaced-repetition-learning-system)
14. [Difficulty and Adaptive Speed](#difficulty-and-adaptive-speed)
15. [Boss Review Rounds](#boss-review-rounds)
16. [Daily Goal and Streak Tracking](#daily-goal-and-streak-tracking)
17. [Game Over Screen](#game-over-screen)
18. [Sound](#sound)
19. [QA / Testing Mode](#qa--testing-mode)
20. [Pause](#pause)

---

## Overview

**Words of the Dead** is a Mac vocabulary-learning game inspired by *The Typing of the Dead*. The player fights off waves of zombies by correctly answering vocabulary questions. The game draws from an ~800-word enriched vocabulary list (a merged 8th/9th-grade SAT word set) and teaches word meanings through four rotating challenge types, spaced repetition, and escalating difficulty.

**Core goal:** Vocabulary mastery, not typing speed. Every correct kill reveals a hand-authored "fun" definition that contextualizes the word in pop-culture scenarios (The Simpsons, Jurassic Park, Premier League soccer, etc.).

---

## Technical Platform

- **Language/Framework:** Swift + SwiftUI (AppKit bridge for key monitoring)
- **Target:** macOS universal binary (arm64 + x86_64)
- **Entry point:** `WordsOfTheDead/Sources/WordsOfTheDeadApp.swift`
- **Build:** `./WordsOfTheDead/build.sh` (set `WOTD_NO_OPEN=1` to skip auto-launch)
- **QA mode:** `open WordsOfTheDead.app --args --qa`
- **Persistence root:** `~/Library/Application Support/WordsOfTheDead/`

### Key source files

| File | Role |
|------|------|
| `Engine/GameEngine.swift` | Game loop: phases, spawning, scoring, lives, levels |
| `Engine/WordScheduler.swift` | Spaced-repetition word selection |
| `Engine/QuestionGenerator.swift` | Builds rounds for all four challenge types |
| `Engine/SoundManager.swift` | Sound effects (explosion on zombie kill) |
| `Views/GameView.swift` | Root view router + all screen views except playfield |
| `Views/PlayfieldView.swift` | Active play layout, zombie rendering, answer UI |
| `Views/AnswerChoicesView.swift` | HUD, answer choice UI, reveal card |
| `Views/CutsceneView.swift` | Opening story cutscene |
| `Models/VocabWord.swift` | Vocabulary word model + `ActiveZombie` + `RoundKind` |
| `Models/WordProgress.swift` | Per-word spaced-repetition state (Leitner box) |
| `Models/Player.swift` | Player profile model |
| `Data/VocabularyStore.swift` | Loads vocabulary, fun definitions, and synonym sets |
| `Data/PlayerStore.swift` | Roster persistence |
| `Data/LearningStore.swift` | Learning profile persistence |
| `Data/DailyGoalStore.swift` | Daily goal persistence |
| `Data/BackgroundStore.swift` | Background image assignment persistence |

---

## Data Files and Content

### Vocabulary
- **Source:** `data/vocab.json` (merged 8th + 9th grade, ~800+ words)
- **Each entry:** `word`, `pos` (n/v/adj/adv), `shortDefinition`, optional `minLevel`, optional `tier` (0–3)
- Only words that have a `funDefinition` in `fun_definitions.json` are **playable** (used for actual zombie questions). All words are available as distractor choices.
- **Synonym data:** `data/synonym-words.txt`, pipe-delimited: `word | syn1 | syn2 | syn3 || related1 | related2 | related3`

### Fun Definitions
- `data/fun_definitions.json` — hand-authored definitions referencing pop-culture (The Simpsons, Cobra Kai, Premier League, Great British Bake-Off, San Francisco landmarks, cat/penguin/seal humor, fencing, Jurassic Park, Lord of the Flies, Hitchhiker's Guide, Gordon Korman, Farmer Boy)
- **Format:** `{"definitions": [{"word": "...", "funDefinition": "..."}]}`
- **QA overrides:** `~/Library/Application Support/WordsOfTheDead/fun_overrides.json` layered on top

### Background Images
- **Location in bundle:** `Resources/backgrounds/*.jpg`
- **Pool A (regular levels):** All images *without* the `sf-` prefix — one assigned per non-boss level
- **Pool B (boss levels):** All images *with* the `sf-` prefix (San Francisco landmarks) — one assigned per multiple-of-5 level
- **Assignment:** Persisted in `~/Library/Application Support/WordsOfTheDead/background_assignments.json` — a given level always gets the same image. When new images are added to the bundle, they fill the next "black" (unassigned) higher levels without disturbing existing assignments.
- If a pool runs out of images, those levels show a plain black background.

### Cutscene Images
- `accomplished.png` — used in scene 2 (job interview)
- `zombies-escape.png` — used in scene 3 (zombie escape)

---

## Player Profiles and Persistence

### First Launch
On first launch (no saved players), the app goes directly to the **Start Screen** (see below), which shows an inline name-entry form in place of the buttons. After the player enters their name and clicks "Begin", the cutscene plays (once), then gameplay starts.

### Returning Launch
The last-used player is automatically activated on launch, skipping the player-select screen entirely. The app goes straight to the **Start Screen** (or cutscene if, somehow, that player hasn't watched it). The "Switch" button on the start screen opens the player-select screen for changing accounts.

### Player Data Model (`Player.swift`)
| Field | Description |
|-------|-------------|
| `id` | Filesystem-safe slug |
| `name` | Display name |
| `bestLevel` | Highest level reached in any run |
| `bestScore` | Highest score |
| `gamesPlayed` | Total games played |
| `hasWatchedCutscene` | Whether the opening cutscene has been shown (once per player) |
| `lastPlayedAt` | Timestamp for sorting |

### File Layout
```
~/Library/Application Support/WordsOfTheDead/
  players.json                          ← roster + lastPlayerID + legacyMigrated
  players/<id>/
    learning_profile.json               ← spaced-repetition state per word
    daily_goal.json                     ← daily practice counts
  background_assignments.json           ← level → background image name
  fun_overrides.json                    ← QA-corrected fun definitions
```

### Slug Identity
Names map to IDs via: lowercase → non-alphanumeric-to-hyphen → collapse hyphens. A "new" player whose name matches an existing slug continues that existing profile.

### Legacy Migration
Pre-player progress (top-level `learning_profile.json` and `daily_goal.json`) migrates exactly once into the first player created, then those files are renamed `*.migrated.json`. The `legacyMigrated` flag in the roster ensures no later player can inherit this old progress.

---

## Opening Cutscene

The cutscene plays **once per player** the first time they start. Returning players skip directly to the start screen.

### Scene Flow

| Scene | Background | Content | Advances |
|-------|-----------|---------|---------|
| **Scene 1** | Black | Silence; distant groaning sounds; corporate jingle begins | Auto after 3 seconds |
| **Scene 2** | `accomplished.png` (job interview photo) | Initial text (size 24): job offer narrative. Delayed text after 2.5s (size 36): "Unfortunately, you're competing against dozens of other applicants." | Continue button appears 1s after delayed text |
| **Scene 3** | `zombies-escape.png` (zombie chaos) | Initial text (size 36): "Instead of a traditional job interview, you're all given a challenge." Delayed text after 2.5s (size 24): zombie backstory (capsule dropped, zombies ate books, roam library). | Continue button |
| **Scene 4** | Black | Initial text (size 36): zombie's challenge quote. Delayed text after 2.5s (size 24): "The applicant with the highest zombie count earns the position. Second place gets— Just kidding - there IS no second place." | Continue button |
| **Scene 5** | Black | Giant zombie emoji (120pt), glowing green "WORDS OF THE DEAD" title (72pt bold), "Tap to begin..." | Tap anywhere |

### Scene 5 ends and calls `engine.markCutsceneWatched()` which sets `hasWatchedCutscene = true` and starts the game.

### Audio
A synthesized corporate C-E-G major-chord jingle (2 seconds, PCM WAV generated at runtime, volume 0.3) plays when the cutscene begins.

### Visual Details
- All text scenes: white left-aligned text on a semi-transparent black card, max-width 800pt
- Vignette (radial gradient, black opacity 0.4) over full screen for readability
- Black fade overlay between scenes

---

## Game Start Screen

The start screen is shown after player selection and after the cutscene for returning players.

### Layout (top to bottom)
1. **Background:** Dark gradient with 6 shambling zombie silhouettes drifting slowly across screen at ~28% opacity
2. **Title:** "WORDS OF THE DEAD" (52pt black rounded font, green gradient, pulsing glow). Subtitle: "SURVIVE THE VOCABULARY ONSLAUGHT" (small, spaced tracking, low opacity)
3. **If no player exists yet — Name Entry form:**
   - "Welcome! What's your name?" label
   - Text field (auto-focused)
   - "Begin" button (green, prominent) — calls `createPlayer(named:)`, leads to cutscene
4. **If a player is active:**
   - **Player bar:** Current player name with person icon and a "Switch" button (opens player-select screen)
   - **Stats strip:** Best Level (green) / Mastered word count (yellow) / Total Words (white dim) in a 3-column card
   - **Daily streak block:** Flame or target icon, day streak count, today's progress `N/20`, orange/yellow progress bar, 7-day activity calendar (green dots for met days, yellow ring for today)
   - **Action buttons:**
     - **Start Game** (green, prominent) — starts at level 1
     - **Test Mode** (orange, bordered) — 1 word per level to quickly advance through levels
     - Caption: "Press P to pause the game at any time."

### Zombie Parade
Six `ZombieFigure` instances (cycling through all three ZombieKind variants) positioned at staggered heights, slowly drifting rightward (12-second loop, looping). They sway slightly left-right.

---

## Level Intro Screen

Displayed for **1.8 seconds** before each level begins. The game is in `.levelIntro` phase during this time (zombies cleared, timer paused).

### Regular Level
- "Level" label (40pt semibold, white)
- Level number (120pt heavy rounded, green glow)
- Instruction text for the current challenge type (title3 bold, white)
- Reminder: "A wrong guess speeds the zombie up. Press P to pause."

### Boss Level (every 5th level)
- "☠️ BOSS REVIEW" (34pt heavy rounded, red)
- "Only the words you've struggled with — and they're faster!"
- Level number in red

### Unlock trigger
At each level intro, the scheduler's `unlockedTier` is updated: `min(3, (level - 1) / 2)`. This controls which word difficulty tiers can appear as *new* introductions:
- Levels 1–2: tier 0 only
- Levels 3–4: tiers 0–1
- Levels 5–6: tiers 0–2
- Level 7+: all tiers (0–3)

---

## Playfield Layout

The playfield occupies the full window and is split into two vertical zones:

### 1. HUD (top bar)
Thin bar with semi-transparent black background, two columns:
- **Left:** "Zombies Killed: N" (green) / "Level: N" (cyan) + "☠️ BOSS" badge if boss level
- **Right:** "Lives: N" (red) / "Mastered: N / Total" (yellow)

### 2. Attack Zone (all remaining height)
Full-screen playfield where all interaction happens. Contains:
- **Background:** Level-assigned background image (scaled-to-fill) with a dark top-to-bottom gradient overlay (black 30% → black 62%). Plain black if no image assigned.
- **Danger line:** 4px red bar at the very bottom — zombies reaching it cost a life
- **Zombies:** Falling animated figures with their prompt and answer choices embedded directly around them
- **Reveal card:** After a correct kill, slides up from the bottom of the attack zone as a full-width card with a dark background (black 80%), showing the word, part of speech, mastery badge, and fun definition for 3 seconds. Other zombies continue falling behind it.

### Overlays
- **Pause overlay:** Full-screen black 65% + "⏸ Paused" + "Press P to resume"
- **Streak banner:** "🔥 STREAK — you got a new life!" centered pop-up, shown for 1.8 seconds

---

## Visual Design: Zombie Art

Zombies are drawn using **SwiftUI Canvas** (`ZombieFigure.swift` embedded in `PlayfieldView.swift`). Three variants:

### ZombieKind Variants

| Kind | Aura Color | Eye Color | Skin (lit/dark) | Cloth (lit/dark) | Special |
|------|-----------|----------|----------------|-----------------|---------|
| **classic** (green shambler) | Green (0.40, 0.80, 0.20) | Red | Olive/dark olive | Dark teal/darker | Standard bare-headed |
| **ghoul** (purple) | Purple (0.62, 0.30, 0.85) | Yellow | Lavender/dark mauve | Deep purple/darker | Stringy-hair silhouette |
| **reaper** (teal) | Teal (0.20, 0.80, 0.80) | Orange | Off-white/gray | Near-black/darkest | Hooded; skull face |

### Drawing Details (Canvas-based)
- **Soft ground shadow:** ellipse at 95% height
- **Legs:** staggered for shambling stance, with lit/shadowed gradient limbs
- **Torso/robe:** gradient-shaded trapezoid with tattered hemline (zigzag path)
- **Arms:** two angled reaching arms with gradient shading
- **Head:** ellipse with gradient skin, sunken face
- **Eyes:** two glowing ellipses in the variant's eye color
- **Hooded reaper:** additional cowl shape over the head; skull-like face (no hair)
- **Tattered robes:** zigzag hem near the bottom of the torso

### ZombieView Animations (SwiftUI)
- **Sway:** rotates ±4° anchored at the base, 1.1s repeating ease-in-out
- **Lurch:** bobs ±3pt vertically, 0.7s repeating ease-in-out; aura pulse 1.08/0.92 scale
- **Aura:** RadialGradient circle behind the figure, blurred, pulsing
- **Wrong answer:** red shadow ring (18pt radius) when `wrong == true`; red outline on the prompt card
- **Explosion:** RadialGradient yellow/orange burst scales to 1.8×, figure scales to 0.1 and fades to 0; takes 0.5s
- **Lead vs. preview:** lead zombie at full opacity (1.0); other zombies at 0.8

### Zombie Prompt Label
- **Definition/Synonym levels:** Large serif text (30pt heavy, letter-spaced), white on near-black rounded card, outlined with the zombie's aura color
- **Fill-in-the-blank/Reverse-definition:** Smaller serif (21pt semibold), wrapped text, max 380pt wide, same card style

---

## Level Types (Challenge Modes)

Levels rotate through four types in strict order: `(level - 1) % 4`:
- Level 1, 5, 9, … → **Type 1: Word-to-Definition**
- Level 2, 6, 10, … → **Type 2: Synonym**
- Level 3, 7, 11, … → **Type 3: Reverse-Definition**
- Level 4, 8, 12, … → **Type 4: Fill-in-the-Blank**

Note: Boss levels (multiples of 5) override word selection but **not** the challenge type.

---

### Type 1: Word-to-Definition

**Zombie shows:** The vocabulary WORD (large serif label)

**Answer area:** 2-column grid of 4 definitions. One correct, two plausible distractors (same part of speech), one obviously-wrong (different part of speech). Choices are shuffled.

**Correct choice starts:** at a random position among the four.

**Controls:**
- **Click** any choice → immediately resolves
- **J key** → cycles to next choice (wraps around)
- **Space** → confirms the currently highlighted choice

**On correct:** Zombie explodes (0.5s animation + sound), reveal card appears in the answer area for 3 seconds. Next zombie may pre-spawn immediately.

**On wrong:** Combo resets, zombie lurches forward (+8% progress) and speeds up (×1.4, capped at maxSpeed). Red highlight appears on the zombie.

**On reach bottom:** Life lost. Word re-queued for this session.

---

### Type 2: Synonym

**Zombie shows:** The vocabulary WORD (same serif label)

**Answer area:** 3-column grid of 6 buttons — 3 true synonyms (from `synonym-words.txt`) and 3 related-but-wrong words, shuffled.

**Goal:** Click all 3 synonyms. They may be clicked in any order.

**On correct click:** Button turns green (stays highlighted), glowing green shadow.

**On wrong click:** Button turns red, zombie lurches (+8%, ×1.4 speed), wrong indices tracked.

**On all 4 selected:** Zombie defeated (same explode + reveal sequence).

**Fallback:** If a word has no synonym entry with ≥3 synonyms and ≥3 related words, a definition round is used instead.

---

### Type 3: Reverse-Definition (Definition-to-Word)

**Zombie shows:** The short DEFINITION (smaller wrapped text on zombie card)

**Answer area:** Same 2-column 4-choice grid as Type 1, but showing WORDS instead of definitions. One correct word, two distractors of same part of speech, one of different part of speech.

**Controls:** Same as Type 1 (click/J cycle/Space confirm).

---

### Type 4: Fill-in-the-Blank

**Zombie shows:** The fun definition with the vocabulary word replaced by `_____` (the exact inflected form is blanked, e.g., "abetted" is blanked even if the listed word is "abet").

**Answer area:** Two large buttons side by side:
- Left button labeled **F** (green circle key badge) with one word
- Right button labeled **J** (green circle key badge) with the other word

One is the correct word (exact inflected form used in the sentence), the other is a plausible distractor of the same part of speech. Both buttons are clickable.

**Controls:**
- **F key** or click left button → choose left
- **J key** or click right button → choose right

**Reveal:** Shows the completed sentence with the word in bold yellow (replacing the blank).

---

### Reveal Card (all level types)

Shown in the **bottom answer area** for 3 seconds after a correct kill.

**Contents:**
1. **Word** (52pt heavy rounded, green)
2. **Part of speech** in parentheses (title italic, white 70%)
3. **Mastery badge** (see Learning System):
   - "New" — cyan capsule
   - "Learning" — orange capsule
   - "Known ✓" — green capsule
4. **Fun definition** (23pt, left-justified, max 660pt wide, equal side margins)
   - The vocabulary word and its inflected forms appear **bold and yellow** within the text
   - Tier-0 (8th grade) words show only the short definition (no fun definition on the reveal)

**During reveal:** The attack zone (top) continues to animate. Other zombies keep falling. The newly spawned next zombie is already visible and approaching during the 3-second window.

---

## Game Mechanics

### Phases (GameEngine.Phase)
1. `.playerSelect` — player selection/creation screen
2. `.cutscene` — opening story (new players only)
3. `.start` — start screen
4. `.levelIntro` — level number shown (1.8 seconds)
5. `.playing` — active gameplay
6. `.revealing` — 3-second reveal after correct answer
7. `.gameOver` — end-of-run summary

### Lives
- **Start:** 1 life
- **Gain a life:** Every 5 consecutive correct answers ("STREAK") → +1 life + banner
- **Lose a life:** Any zombie reaches the danger line
- **Game Over:** Lives reach 0

### Words per Level
- **Normal:** 10 words per level
- **Test Mode:** 1 word per level (for fast level navigation during development/testing)

### Zombie Spawning

**Simultaneous zombie cap per level:**
- Levels 1–2: max 2 zombies at once
- Levels 3–4: max 3 zombies
- Level 5+: max 4 zombies

**Spawn triggers (when lead zombie reaches X% down):**
- 2nd zombie spawns at: `max(20%, 55% − 3% × (level − 1))`
- 3rd zombie spawns at: `max(20%, 55% − 3% × (level − 3))`
- 4th zombie spawns at: `max(20%, 55% − 3% × (level − 5))`

So each zombie tier's trigger creeps 3% earlier each level, never going below 20%.

**Carry-over:** When a level ends with zombies still falling, those zombies' words are carried into the next level as "pre-queued" words, appearing first. This ensures a word the player already sees previewed is the one that actually comes next.

**On correct kill:** The next zombie spawns immediately (so it starts falling from the top while the 3-second reveal plays), *unless* the last word of the level was just completed.

### Wrong Answer Penalty
- Progress: `+8%` (jumps the zombie down 8% of the remaining distance)
- Speed: `×1.4`, capped at `maxSpeed = 0.04`
- Combo: resets to ×1.0
- Streak: resets to 0
- Word re-queued: reappears 2–3 spawns later in the same session

### Zombie Reaching the Bottom
- Life lost (−1)
- Streak reset
- Combo reset
- Word demoted in spaced repetition
- Word re-queued for session

### Timer Loop
- Ticks every **50ms** (`tickInterval = 0.05`)
- Each tick advances every zombie's `progress` by its `speed` value
- Pausing stops all progress

---

## Scoring and Combos

### Score Calculation (per kill)
```
speedBonus = (1.0 − zombie.progress) × 100
score += (100 + speedBonus) × comboMultiplier
```
- Killing a zombie high up the screen (low progress) gives a higher speed bonus
- `comboMultiplier` starts at 1.0 and grows with the player's streak

### Combo Multiplier
- **Increment:** `+0.25 per correct answer in a row`, max ×5.0
- **Reset:** Any wrong final answer or zombie reaching bottom → back to ×1.0

### HUD Score Display
The HUD shows: Zombies Killed (left), Level (left), Lives (right), Mastered count (right).  
*(Note: Although a score and combo system exists internally, the current HUD does not display them prominently — they are tracked for end-of-run summary.)*

---

## Spaced-Repetition Learning System

### Leitner Box Model (WordProgress)
Each word has a box (0–5):

| Box | Review Interval |
|-----|----------------|
| 0 | Immediate (due now) |
| 1 | 1 minute |
| 2 | 10 minutes |
| 3 | 1 day |
| 4 | 3 days |
| 5 | 7 days |

- **Correct answer:** Box +1 (up to 5), `dueAt = now + interval(newBox)`
- **Wrong answer / timeout:** Box −1 (down to 0), re-scheduled sooner

### Mastery Stages
- **New:** Never attempted (no profile entry)
- **Learning:** Attempted but box < 4
- **Known:** Box ≥ 4 (answered correctly enough times with increasing spacing)

Mastery stage is shown on the reveal card badge and counted in the HUD/game-over summary.

### Word Selection Priority
Each call to `nextWord()`:
1. **In-session re-queue:** A recently-missed word whose countdown (4–6 spawns) has elapsed
2. **Due review:** Most-overdue word (pick from top 5 oldest, with randomness)
3. **New word:** Introduced 35% of the time when reviews are also available; always from the easiest tier available; easiest words within that tier preferred
4. **Fallback:** Soonest-due word (so play never stalls)

To keep repetition from feeling too immediate, the scheduler also applies a soft repeat cooldown: once a word is served, it will usually not be shown again for at least 6 more served words unless the pool is exhausted.

### Tier Gating
Words are assigned a difficulty tier (0–3) based on word length + estimated syllable count (or bundled `tier` value from `vocab.json`):
- Tier 0: short, simple words (length+syllables×2 < 10)
- Tier 1: medium (10–13)
- Tier 2: harder (14–17)
- Tier 3: hardest (18+)

Only tier 0 words can appear as **new introductions** at levels 1–2. Each two levels, one more tier unlocks. Overdue review words of any tier can still appear regardless of unlock.

### In-Session Re-queue
When the player gets a word wrong (wrong guess or timeout), it is added to an in-session re-queue with a countdown of 4–6 spawns. When the countdown hits zero, that word reappears for immediate reinforcement. Each word is only re-queued at most once per session. The scheduler also keeps a short soft cooldown between any two appearances of the same word.

### Persistence
Learning profiles saved to `players/<id>/learning_profile.json` — a dictionary keyed by lowercased word. Automatically loaded/saved on each outcome.

---

## Difficulty and Adaptive Speed

### Base Fall Speed
`speed = min(maxSpeed, baseSpeed × 1.01^(level−1))`
- `baseSpeed = 0.001089` (progress units per tick at level 1)
- Each level: +1% base speed
- Hard cap: `maxSpeed = 0.04`

### Boss Level Multiplier
Speed ×1.35 on boss levels.

### Adaptive Speed (Rubber-Banding)
Tracks last 8 outcomes (correct/wrong). Maps recent accuracy (0–1) to a speed factor:
- 75% accuracy → ×0.75 (slower, player is struggling)
- ~50% → ×1.0 (neutral)
- 100% → ×1.35 (faster, player is doing well)

`adaptiveFactor = 0.75 + (1.35 − 0.75) × accuracy`

Final speed = `base × adaptiveFactor × bossMultiplier`, capped at `maxSpeed`.

---

## Boss Review Rounds

Every **5th level** (level 5, 10, 15, …) is a "BOSS REVIEW" level.

- **Word selection:** Draws preferentially from words the player has struggled with (wrong answer count > 0, or not yet `known`), most overdue first. Falls back to normal selection if no struggling words exist yet.
- **Speed:** 35% faster than normal speed for that level
- **Background:** Always uses an `sf-` prefixed background image (San Francisco landmarks)
- **HUD:** "☠️ BOSS" badge next to the level number in red
- **Level intro:** Shows "☠️ BOSS REVIEW" in red instead of the normal level card
- **Challenge type:** Still follows the normal 4-type rotation (boss status only affects word selection and speed, not challenge mode)

---

## Daily Goal and Streak Tracking

### Goal
20 words practiced per day (each zombie resolved — correct or timed out — counts as one practice).

### Persistence
`players/<id>/daily_goal.json` — dictionary of date strings → count.

### Start Screen Display
- **Target emoji:** 🎯 (< 2-day streak) or 🔥 (2+ day streak)
- **Day streak count** (consecutive days the goal was met)
- **Today's progress:** `N / 20`
- **Progress bar:** orange-to-yellow gradient (or green if goal met)
- **7-day calendar:** One circle per day, green with checkmark if goal met, yellow ring highlight for today

### Notifications
- **Milestone reached** (7, 14, 30, 60, 100-day streak): system notification
- **Streak at risk** (less than 25% of daily goal done when game ends): system notification

---

## Game Over Screen

Triggered when lives reach 0.

### Layout
- **Background:** Same dark gradient + 6 shambling zombie silhouettes at 35% opacity (same as start screen)
- **Vignette:** Radial gradient black fog overlay

### Headline
Flavor text based on performance:
- 0 kills → "DEVOURED INSTANTLY"
- Level ≥ 10 → "LEGENDARY FALL"
- ≥ 20 kills → "HEROIC LAST STAND"
- Accuracy ≥ 90% → "SO CLOSE…"
- Default → "DEVOURED"

Large (52pt black rounded), red gradient, pulsing red glow.

### Subtitle Lines
- "You permanently learned N word(s) — the undead can never take that from you." (if newly mastered > 0)
- "N word(s) to review — they'll come back to haunt you." (if any missed)

### Stats Card ("Tombstone")
"R.I.P." header strip, then:
- **Zombies Killed** (large 48pt green hero stat)
- 2-column grid: Reached Level / Accuracy / Best Streak / Newly Mastered / Words to Review

### Daily Streak Block
Same as start screen (shows updated streak after this session).

### "Rise Again" Button
Green prominent button appears 1.2 seconds after the screen loads. Clicking restarts the game (goes back to `.start` phase).

---

## Sound

- **Zombie kill:** `Sounds/explosion.wav` (0.7 volume) plays on each correct kill
- **Cutscene jingle:** Synthesized C-E-G major chord (2 seconds, PCM WAV generated at runtime), volume 0.3, plays once when the cutscene begins
- **Sound setting:** Toggle in `UserDefaults` key `sound_effects_enabled` (default on)

---

## QA / Testing Mode

Launch with: `open WordsOfTheDead.app --args --qa`

### QA Review Screen
- White background, black and green text
- Displays all fun sentences 10 at a time
- Arrow links to navigate pages
- Checkbox next to each sentence — click to flag as flawed
- After reviewing, the app suggests corrections for flagged sentences
- Player can accept or type a manual correction
- Corrections saved to `fun_overrides.json` and immediately applied to gameplay

### Test Mode (Start Screen)
- "Test Mode" button on start screen
- Advances to the next level after just **1 word** (instead of 10)
- Useful for quickly cycling through level types and background images

---

## Pause

- **Toggle:** Press **P** during active play (`.playing` phase only)
- **Effect:** The game loop stops advancing zombie positions; all timers freeze
- **Overlay:** Full-screen black 65% overlay with "⏸ Paused" (52pt green) and "Press P to resume"
- **Resume:** Press P again

---

*End of document*
