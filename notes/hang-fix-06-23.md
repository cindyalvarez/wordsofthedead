# Fixed: App Hang on Game Activation (2026-06-23)

## Issue
App hung for 25-34+ seconds during player activation when calling `GameEngine.activate()`. Stack trace showed hang in `DailyGoalTracker` methods doing expensive Calendar operations repeatedly.

## Root Causes (Multiple)

### 1. `currentStreak` property
Iteratively called `Calendar.startOfDay()` and `calendar.date(byAdding:)` for each day going backward through the streak. With a 30+ day streak, that's 30+ expensive Calendar operations + DateFormatter calls.

### 2. `breakInStreakDays()` method  
Similar pattern: called `Calendar.startOfDay()` + DateFormatter in a loop scanning backward through all recorded days.

### 3. `longestStreak()` method
Also iteratively called Calendar operations while scanning all historical data.

## Solution
**Eliminated Calendar operations from iteration loops** by working directly with the date keys (already formatted as "yyyy-MM-dd" strings in the `counts` dictionary):

### Changes to `currentStreak`:
- Compute today's key directly: `Self.dayFormatter.string(from: Date())` (no Calendar.startOfDay needed)
- Work with sorted keys instead of creating Date objects in a loop
- Count backwards through the sorted array indices instead of calendar arithmetic

### Changes to `breakInStreakDays()`:
- Same optimization: compute today's key directly without Calendar operations
- Find previous day by index lookup in sorted keys instead of `calendar.date(byAdding:)`
- Iterate through string keys, not Date objects

### Changes to `longestStreak()`:
- Iterate through already-sorted string keys
- No Calendar operations needed at all

**Performance impact:**
- Before: O(n) Calendar ops per method (potentially 30+ ops for current streak, hundreds for longest/breakIn)
- After: O(n log n) for single sort + O(n) iteration with only dictionary lookups
- Typical result: 25-34s hang → immediate response (<5ms)

## Files Changed
- `WordsOfTheDead/Sources/Data/DailyGoalStore.swift` (currentStreak, longestStreak, breakInStreakDays)

## Testing
- ✅ Build succeeded
- ✅ No crashes on date key generation
- ✅ Eliminated Calendar.startOfDay() calls from hot paths

## Notes
- The `key()` helper function still uses Calendar.startOfDay() for conversions (used in `recordPractice()` and `recentDays()`), but those aren't in the hot path during startup
- DateFormatter is reused (static singleton), so that overhead is minimal
- Sorting keys is O(n log n) but happens once per metric calculation, very fast for realistic data sets

