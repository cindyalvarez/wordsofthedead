# Fix: Remove Fun Definitions for Tier-0 (8th-Grade) Words

## Problem
The newly-added 8th-grade vocabulary (tier-0) had procedurally-generated "fun definitions" that:
1. Were grammatically incoherent - the definition was embedded in the middle of sentences with em-dashes
2. Made no sense as English sentences (e.g., "When the graveyard gate rattled by the Jurassic Park jeep, a neighbor had to accept—to say yes to or receive—before a black headband vanished.")
3. About half were missing entirely

## Solution: Option 1 - Remove fun definitions for tier-0 entirely
This makes pedagogical sense: 8th-graders should learn basic, straightforward definitions first. The more engaging "fun definitions" are better suited for advanced vocabulary at higher tiers.

## Changes Made

### 1. Modified RevealView (Sources/Views/AnswerChoicesView.swift)
- Updated the `highlightedDefinition` property to skip fun definitions for tier-0 words
- For tier-0 words: always uses `shortDefinition`
- For higher-tier words: uses `funDefinition` if available, falls back to `shortDefinition`

**Code change:**
```swift
// Before:
let text = word.funDefinition ?? word.shortDefinition

// After:
let text = (word.tier == 0 ? nil : word.funDefinition) ?? word.shortDefinition
```

### 2. Removed tier-0 entries from fun definition data files
- Removed 32 entries from `data/fun_definitions.json`
- Removed 32 entries from `data/fun_definitions_combined.json`
- Ensures QA Review screen only shows fun definitions for tier 1+ words

## Result
- Tier-0 (8th-grade) words now display clean, straightforward definitions
- Example: "abhor" → "to regard with disgust and hatred; detest" (not a broken fun sentence)
- Higher-tier words continue to show engaging fun definitions
- QA Review screen no longer includes problematic tier-0 definitions

## Testing
1. Build: `WOTD_NO_OPEN=1 ./WordsOfTheDead/build.sh`
2. Play early levels to see clean tier-0 definitions
3. Progress to later levels to see fun definitions for advanced vocabulary
4. Run QA Review: `open build/WordsOfTheDead.app --args --qa` - should not show tier-0 words
