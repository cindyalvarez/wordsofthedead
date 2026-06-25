import Foundation

/// Comprehensive streak and engagement metrics for a player.
struct StreakMetrics: Identifiable {
    let id = UUID()
    
    // Current state
    let currentStreak: Int           // Days currently maintained
    let longestStreak: Int           // All-time best streak
    let breakInStreak: Int           // Days since last break
    let daysUntilMilestone: Int      // Days to next milestone
    let nextMilestone: Int           // 7, 14, 30, 60, 100, etc.
    let streakAtRisk: Bool           // Today's progress < 25% of goal
    let timeUntilDeadline: TimeInterval  // Seconds until midnight
    let todayProgress: Int           // Words practiced today
    let todayGoal: Int               // Words needed today (20)
    
    // Computed flags
    var goalMetToday: Bool {
        todayProgress >= todayGoal
    }
    
    var isBroken: Bool {
        currentStreak == 0
    }
    
    var isRebuildingAfterBreak: Bool {
        isBroken && breakInStreak > 0
    }
    
    /// Motivational message based on streak length
    var streakMessage: String {
        switch currentStreak {
        case 0:
            return "Let's rebuild together"
        case 1...3:
            return "Starting strong!"
        case 4...7:
            return "Momentum building!"
        case 8...14:
            return "Week Warrior!"
        case 15...30:
            return "Month Champion!"
        case 31...60:
            return "Legend status!"
        default:
            return "Absolutely legendary!"
        }
    }
    
    /// Emoji for visual representation
    var streakEmoji: String {
        switch currentStreak {
        case 0:
            return "😢"
        case 1..<3:
            return "💪"
        case 3..<7:
            return "🚀"
        case 7..<14:
            return "🌟"
        case 14..<30:
            return "⚡"
        case 30..<60:
            return "👑"
        default:
            return "💎"
        }
    }
    
    /// Milestone badge (e.g., "Week Warrior", "Month Champion")
    var milestoneBadge: String? {
        switch nextMilestone {
        case 7:
            return "Week Warrior"
        case 14:
            return "Fortnight Master"
        case 30:
            return "Month Champion"
        case 60:
            return "Season King"
        case 100:
            return "Century Collector"
        default:
            return nil
        }
    }
    
    /// Next milestone number (7, 14, 30, 60, 100)
    static func nextMilestoneNumber(for streak: Int) -> Int {
        switch streak {
        case 0..<7:
            return 7
        case 7..<14:
            return 14
        case 14..<30:
            return 30
        case 30..<60:
            return 60
        case 60..<100:
            return 100
        default:
            return (streak / 100 + 1) * 100  // Next century
        }
    }
}
