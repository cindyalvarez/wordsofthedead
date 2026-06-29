# Words of the Dead - Vocabulary Tier System Implementation

## Overview
The Words of the Dead game now uses a two-tier vocabulary system that progressively introduces age-appropriate content:
- **Tier 1 (Levels 1-50)**: 500 8th-grade level vocabulary words with engaging, pop-culture based definitions
- **Tier 2 (Levels 51+)**: 988 original advanced vocabulary words from the original vocablist.txt

This implementation ensures new players encounter content appropriate for middle school reading levels before graduating to advanced academic vocabulary.

## Implementation Summary

### Files Generated
1. **data/vocab_8th_grade.json** (500 words)
   - 8th-grade appropriate vocabulary with definitions
   - Marked with minLevel: 1 for levels 1-50
   - Each word has engaging pop-culture example sentences

2. **data/fun_definitions_8th_grade.json** (500 definitions)
   - Fun sentences for 8th-grade vocabulary
   - Format: `{ "definitions": [ { "word": "...", "funDefinition": "..." } ] }`

3. **data/fun_definitions_combined.json** (1488 definitions)
   - Complete fun definitions for all 1488 words (8th-grade + original)
   - 100% coverage ensures every word displayed has an engaging example

### Swift Code Modifications

#### VocabWord.swift
- Added `minLevel: Int` field to track minimum game level for word appearance
- Added `bundledTier: Int?` field for optional tier bundling
- Updated `tier` computed property to use `bundledTier` if available

#### VocabularyStore.swift
- Updated `RawVocabEntry` struct to decode `minLevel` and `tier` fields from JSON
- Modified `VocabWord` initialization to pass `minLevel` and `bundledTier` to constructor

#### WordScheduler.swift
- Changed `nextWord()` → `nextWord(forLevel:)` to filter words by minimum level
- Updated `reviewWord()` → `reviewWord(forLevel:)` for boss level word filtering
- All word selection logic now includes `&& $0.minLevel <= level` filter
- Words remain hidden until player reaches their minimum level

#### GameEngine.swift
- Updated `takeNextWord()` to pass current `level` parameter to scheduler methods
- Both regular and boss level word selection now respects level gates

### Vocabulary Merging Strategy

The build process (via `tools/parse_vocab.py`) now:
1. First loads 8th-grade vocabulary (minLevel: 1)
2. Then loads original vocablist.txt words (minLevel: 51)
3. Gives priority to 8th-grade versions if a word appears in both
4. Final output: 1488 merged entries with proper level gating

**Build Integration:**
```bash
# Parse 8th-grade vocabulary (500 words, minLevel 1)
# Parse original vocablist.txt (988 words, minLevel 51)
# Merge with 8th-grade priority → data/vocab.json
# Copy to app bundle → build/WordsOfTheDead.app/Contents/Resources/vocab.json
```

## Word Filtering Logic

### How It Works
1. When a word is scheduled, WordScheduler checks: `word.minLevel <= currentPlayerLevel`
2. Level 1-50: Only 8th-grade words (minLevel 1) are available
3. Level 51+: Original advanced words (minLevel 51+) become available
4. No hard cutoff—original words gradually appear as player levels progress

### Boss Levels
- Boss levels (every 5th level) draw from the player's learned words (review pool)
- But still respect the level gate: only words with `minLevel <= currentLevel` are reviewed
- Player at level 47 can only review 8th-grade words
- Player at level 52 can review both 8th-grade and original words

## Testing & Verification

### Vocabulary Distribution (Verified)
✓ 500 8th-grade words marked with minLevel: 1
✓ 988 original words marked with minLevel: 51
✓ 1488 total entries in merged vocabulary
✓ 100% coverage of fun definitions (1488/1488)

### Code Verification (Verified)
✓ VocabWord.swift: minLevel field present
✓ VocabularyStore.swift: minLevel decoding implemented
✓ WordScheduler.swift: forLevel filtering implemented
✓ GameEngine.swift: forLevel parameter passed correctly

### Build Verification (Verified)
✓ App bundle contains vocab.json with 1488 entries
✓ 500 entries with minLevel: 1 (8th-grade)
✓ 988 entries with minLevel: 51 (original)
✓ Fun definitions file copied to bundle (100% coverage)

## Example 8th-Grade Words

Sample of vocabulary included in Tier 1:
- ability, accept, accident, achieve, act
- distance, distant, divide, young, zoom
- worry, write, yell

All with engaging definitions like:
> "At the prep bench, Bart learned that ability means the power or skill to do something, just like his ability to create pranks was legendary!"

## Future Enhancements

- [ ] Progressive difficulty curves (more granular level gating)
- [ ] Difficulty tiers within 8th-grade vocabulary (basic → intermediate → advanced)
- [ ] Player profiling for individual reading level adaptation
- [ ] Analytics on when players reach 51+ vocabulary

## How to Rebuild

The vocabulary system is fully automated. To rebuild with changes:

```bash
cd /Users/cindya/vibe/wordsofthedead
WOTD_NO_OPEN=1 bash WordsOfTheDead/build.sh
```

The build process will:
1. Parse vocab_8th_grade.json
2. Parse vocablist.txt
3. Merge with 8th-grade priority
4. Copy to app bundle
5. Generate fun sentences file

## References

- WordsOfTheDead/Sources/Models/VocabWord.swift
- WordsOfTheDead/Sources/Data/VocabularyStore.swift
- WordsOfTheDead/Sources/Engine/WordScheduler.swift
- WordsOfTheDead/Sources/Engine/GameEngine.swift
- tools/parse_vocab.py
- tools/generate_8th_grade_vocab.py (generation script)
