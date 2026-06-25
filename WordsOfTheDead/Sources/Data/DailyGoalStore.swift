import Foundation

/// One day's worth of practice activity, used by the start/game-over calendar.
struct DayActivity: Identifiable {
    let id: String          // yyyy-MM-dd
    let label: String       // weekday initial, e.g. "M"
    let count: Int
    let met: Bool
    let isToday: Bool
}

/// Tracks how many words the player practices each day and the consecutive-day streak of
/// hitting the daily goal. Pairs with spaced repetition: a "day" of review keeps the
/// streak alive. Persisted to:
///
/// `~/Library/Application Support/WordsOfTheDead/daily_goal.json`
@MainActor
final class DailyGoalTracker {
    /// Words to practice per day to keep the streak alive.
    let goal = 20

    private var counts: [String: Int]
    private let calendar = Calendar.current

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    init() {
        counts = DailyGoalStore.load()
    }

    private func key(for date: Date) -> String {
        Self.dayFormatter.string(from: calendar.startOfDay(for: date))
    }

    // MARK: - Recording

    /// Counts one practiced word toward today's goal.
    func recordPractice(count: Int = 1) {
        let k = key(for: Date())
        counts[k, default: 0] += count
        DailyGoalStore.save(counts)
    }

    // MARK: - Stats

    var todayCount: Int { counts[key(for: Date())] ?? 0 }

    var goalMetToday: Bool { todayCount >= goal }

    /// Consecutive days (ending today, or yesterday if today is still in progress) on which
    /// the daily goal was met.
    var currentStreak: Int {
        // Compute today's key efficiently
        let today = Self.dayFormatter.string(from: Date())
        
        // Today still counts as "in progress" until the goal is met; don't break the streak.
        if (counts[today] ?? 0) < goal {
            // Check yesterday - find previous key in sorted list
            let sortedKeys = counts.keys.sorted()
            guard let todayIndex = sortedKeys.firstIndex(of: today), todayIndex > 0 else {
                return 0
            }
            let yesterday = sortedKeys[todayIndex - 1]
            if (counts[yesterday] ?? 0) < goal {
                return 0
            }
            // Yesterday met goal, start counting from yesterday
            var streak = 1
            var currentIndex = todayIndex - 1
            while currentIndex > 0 {
                currentIndex -= 1
                if (counts[sortedKeys[currentIndex]] ?? 0) >= goal {
                    streak += 1
                } else {
                    break
                }
            }
            return streak
        }
        
        // Today met goal, count backwards from today
        let sortedKeys = counts.keys.sorted()
        guard let todayIndex = sortedKeys.firstIndex(of: today) else {
            return 0
        }
        
        var streak = 1
        var currentIndex = todayIndex
        while currentIndex > 0 {
            currentIndex -= 1
            if (counts[sortedKeys[currentIndex]] ?? 0) >= goal {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }

    /// The last `days` days (oldest → today) for a small activity calendar.
    func recentDays(_ days: Int = 7) -> [DayActivity] {
        let today = calendar.startOfDay(for: Date())
        let initials = ["S", "M", "T", "W", "T", "F", "S"]
        return (0..<days).reversed().compactMap { offset -> DayActivity? in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let k = key(for: date)
            let count = counts[k] ?? 0
            let weekday = calendar.component(.weekday, from: date) - 1 // 0=Sunday
            return DayActivity(
                id: k,
                label: initials[(weekday + 7) % 7],
                count: count,
                met: count >= goal,
                isToday: offset == 0
            )
        }
    }
    
    // MARK: - Engagement Metrics
    
    /// Compute comprehensive streak and engagement metrics.
    func computeMetrics(todayProgress: Int) -> StreakMetrics {
        let current = currentStreak
        let longest = longestStreak()
        let breakIn = breakInStreakDays()
        let today = Date()
        let midnight = calendar.startOfDay(for: today).addingTimeInterval(24 * 3600)
        let timeUntilDeadline = midnight.timeIntervalSince(today)
        let nextMilestone = StreakMetrics.nextMilestoneNumber(for: current)
        let daysUntilMilestone = nextMilestone - current
        let atRisk = todayProgress < (goal / 4)  // < 25% of goal
        
        return StreakMetrics(
            currentStreak: current,
            longestStreak: longest,
            breakInStreak: breakIn,
            daysUntilMilestone: daysUntilMilestone,
            nextMilestone: nextMilestone,
            streakAtRisk: atRisk,
            timeUntilDeadline: timeUntilDeadline,
            todayProgress: todayProgress,
            todayGoal: goal
        )
    }
    
    /// Longest streak ever achieved (all-time best).
    private func longestStreak() -> Int {
        guard !counts.isEmpty else { return 0 }
        
        // Sort keys chronologically to iterate efficiently through recorded days
        let sortedKeys = counts.keys.sorted()
        
        var maxStreak = 0
        var currentStreak = 0
        
        for key in sortedKeys {
            if (counts[key] ?? 0) >= goal {
                currentStreak += 1
            } else {
                maxStreak = max(maxStreak, currentStreak)
                currentStreak = 0
            }
        }
        maxStreak = max(maxStreak, currentStreak)
        return maxStreak
    }
    
    /// Consecutive days since the last time the streak was broken (rebuild counter).
    private func breakInStreakDays() -> Int {
        // Compute today's key efficiently without expensive calendar operations
        let today = Self.dayFormatter.string(from: Date())
        
        // If today or yesterday met goal, streak is still active
        if (counts[today] ?? 0) >= goal {
            return 0
        }
        
        // Check yesterday by finding the previous day in the sorted keys
        let sortedKeys = counts.keys.sorted()
        guard let todayIndex = sortedKeys.firstIndex(of: today) else {
            // Today not in history, check if streak is active from earlier days
            if let prevKey = sortedKeys.last, (counts[prevKey] ?? 0) >= goal {
                return 0
            }
            return 0
        }
        
        if todayIndex > 0 {
            let previousKey = sortedKeys[todayIndex - 1]
            if (counts[previousKey] ?? 0) >= goal {
                return 0
            }
        }
        
        // Streak is broken, count days back from today until we find a goal-met day
        var breakInDays = 0
        for key in sortedKeys.reversed() {
            if key > today {
                continue
            }
            if (counts[key] ?? 0) < goal {
                breakInDays += 1
            } else {
                break
            }
        }
        
        return breakInDays
    }
}

/// Persists the per-day practice counts (`[yyyy-MM-dd: wordsPracticed]`), namespaced per
/// player via `playerID`.
enum DailyGoalStore {
    /// Identifier of the player whose history is being read/written.
    static var playerID: String = "default"

    static var fileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let dir = base
            .appendingPathComponent("WordsOfTheDead", isDirectory: true)
            .appendingPathComponent("players", isDirectory: true)
            .appendingPathComponent(playerID, isDirectory: true)
        return dir.appendingPathComponent("daily_goal.json")
    }

    static func load() -> [String: Int] {
        let decoder = JSONDecoder()
        
        // Try loading with error recovery
        if let recovered: [String: Int] = FileUtilities.loadWithRecovery(from: fileURL, decoder: decoder) {
            return recovered
        }
        
        // Fallback to empty history
        FileUtilities.log("Daily goal history load failed, using empty history", category: "load")
        return [:]
    }

    @discardableResult
    static func save(_ counts: [String: Int]) -> Bool {
        guard let data = try? JSONEncoder().encode(counts) else {
            FileUtilities.log("Failed to encode daily goal history", category: "save")
            return false
        }
        
        // Create backup before writing
        FileUtilities.createBackupIfNeeded(for: fileURL)
        
        // Write atomically
        return FileUtilities.writeAtomically(data, to: fileURL)
    }

    /// Pre-player-system location of the global daily-goal history.
    private static var legacyURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return base
            .appendingPathComponent("WordsOfTheDead", isDirectory: true)
            .appendingPathComponent("daily_goal.json")
    }

    /// Where the legacy file is moved once it has been migrated, so it is preserved as a
    /// backup but can never be migrated into a player again.
    private static var consumedLegacyURL: URL {
        legacyURL.deletingLastPathComponent().appendingPathComponent("daily_goal.migrated.json")
    }

    /// One-time migration: if a legacy (pre-player) history exists and the current player has
    /// none yet, copy it in so the earlier daily streak isn't lost. The legacy file is then
    /// consumed so no later player can inherit it.
    static func migrateLegacyIfNeeded() {
        let fm = FileManager.default
        guard fm.fileExists(atPath: legacyURL.path) else { return }
        if !fm.fileExists(atPath: fileURL.path) {
            try? fm.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? fm.copyItem(at: legacyURL, to: fileURL)
        }
        consumeLegacy()
    }

    /// Renames the legacy top-level history so a future "first" player (e.g. after a roster
    /// reset) can never re-inherit pre-player progress. Safe to call repeatedly.
    static func consumeLegacy() {
        let fm = FileManager.default
        guard fm.fileExists(atPath: legacyURL.path) else { return }
        try? fm.removeItem(at: consumedLegacyURL)
        try? fm.moveItem(at: legacyURL, to: consumedLegacyURL)
    }
}
