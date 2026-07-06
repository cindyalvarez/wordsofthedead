# Explosion Sound Effect Feature

## Overview
Added a satisfying explosion sound effect that plays when the player defeats a zombie in Words of the Dead.

## Changes Made

### 1. Created SoundManager (`Sources/Engine/SoundManager.swift`)
- New `@MainActor` class that manages all game sound effects
- Provides `playExplosion()` method to trigger the explosion sound
- Respects a `soundEffectsEnabled` setting persisted to UserDefaults
- Uses `AVAudioPlayer` with proper memory management
- Sound files stored in `Resources/Sounds/` subdirectory

### 2. Generated Explosion Sound (`Resources/Sounds/explosion.wav`)
- Created a satisfying 0.8-second explosion sound file
- Combines a deep 80Hz boom with exponential decay
- Adds white noise element for realistic explosion effect
- Volume set to 0.7 (70%) to avoid clipping

### 3. Integrated Sound into GameEngine (`Sources/Engine/GameEngine.swift`)
- Modified `resolveLead()` method to call `SoundManager.shared.playExplosion()`
- Sound plays immediately when a correct answer is detected
- Plays synchronously with the explosion animation

### 4. Updated Build Script (`WordsOfTheDead/build.sh`)
- Added line to copy `Resources/Sounds/` directory to app bundle
- Ensures sound files are available when app is distributed

## Testing
1. Build the app: `WOTD_NO_OPEN=1 ./WordsOfTheDead/build.sh`
2. Launch in QA mode: `open build/WordsOfTheDead.app --args --qa`
3. Play the game and answer a question correctly to hear the explosion sound

## Future Enhancements
- Add settings UI toggle for sound effects on/off
- Add additional sound effects (correct answer chime, game over, level up)
- Add sound volume control slider
- Consider different explosion variations for larger streaks
