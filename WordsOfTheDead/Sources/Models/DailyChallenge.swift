import Foundation

/// A daily challenge to encourage engagement and goal-setting.
struct DailyChallenge: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let reward: String  // e.g., "+2 XP", "+50 pts"
    var isCompleted: Bool = false
    let createdDate: Date
    
    init(
        id: String = UUID().uuidString,
        title: String,
        description: String,
        reward: String,
        createdDate: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.reward = reward
        self.createdDate = createdDate
    }
}

/// Generates and rotates daily challenges based on player state and session history.
enum DailyChallengeGenerator {
    
    /// Generate today's challenges based on yesterday's performance and streak status.
    static func generateChallenges(
        yesterdayScore: Int?,
        streakLength: Int,
        wordsLearned: Int,
        totalWords: Int,
        sessionIndex: Int
    ) -> [DailyChallenge] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: today) ?? 1
        
        // Use day of year as seed for consistent rotation
        let seed = (dayOfYear + sessionIndex) % 3
        
        let challenges: [[DailyChallenge]] = [
            // Rotation 0: Learn + Master + Score
            [
                DailyChallenge(
                    id: "learn-3-words",
                    title: "Learn 3 New Words",
                    description: "Expand your vocabulary today",
                    reward: "+2 XP"
                ),
                DailyChallenge(
                    id: "master-word",
                    title: "Master a Tough Word",
                    description: "Review: \(nextToughWord(from: totalWords))",
                    reward: "+5 XP"
                ),
                DailyChallenge(
                    id: "beat-score",
                    title: "Beat Yesterday's Score",
                    description: yesterdayScore.map { "You scored \($0) pts" } ?? "Set a baseline",
                    reward: "+1 XP"
                )
            ],
            
            // Rotation 1: Accuracy + Streak + Collection
            [
                DailyChallenge(
                    id: "high-accuracy",
                    title: "Achieve 85%+ Accuracy",
                    description: "Focus on quality over speed",
                    reward: "+3 XP"
                ),
                DailyChallenge(
                    id: "extend-streak",
                    title: "Keep Your Streak Alive",
                    description: "You're on a \(streakLength)-day streak!",
                    reward: "+Streak"
                ),
                DailyChallenge(
                    id: "collect-10",
                    title: "Practice 10+ Words",
                    description: "More practice = faster mastery",
                    reward: "+2 XP"
                )
            ],
            
            // Rotation 2: Speed + Completion + Challenge
            [
                DailyChallenge(
                    id: "quick-study",
                    title: "Answer 5 in a Row",
                    description: "Build your combo multiplier",
                    reward: "+4 XP"
                ),
                DailyChallenge(
                    id: "complete-session",
                    title: "Complete Full Session",
                    description: "Reach level 5 or higher",
                    reward: "+3 XP"
                ),
                DailyChallenge(
                    id: "master-category",
                    title: "Master a Category",
                    description: "Focus on similar words",
                    reward: "+6 XP"
                )
            ]
        ]
        
        return challenges[seed]
    }
    
    /// Check if a challenge is completed and update if needed.
    static func checkCompletion(
        challenge: inout DailyChallenge,
        stats: SessionStats
    ) {
        switch challenge.id {
        case "learn-3-words":
            challenge.isCompleted = stats.wordsLearned >= 3
        case "high-accuracy":
            challenge.isCompleted = stats.accuracy >= 0.85
        case "extend-streak":
            challenge.isCompleted = true  // Completed if session played
        case "collect-10":
            challenge.isCompleted = stats.wordsLearned >= 10
        case "quick-study":
            challenge.isCompleted = stats.bestCombo >= 5
        case "complete-session":
            challenge.isCompleted = stats.levelReached >= 5
        case "beat-score":
            challenge.isCompleted = stats.score >= (SessionStats.lastScore ?? 0)
        case "master-word":
            challenge.isCompleted = stats.wordsMastered >= 1
        case "master-category":
            challenge.isCompleted = stats.wordsMastered >= 5
        default:
            break
        }
    }
    
    /// Find a tough word for the player to focus on (randomly selected).
    private static func nextToughWord(from totalWords: Int) -> String {
        let words = [
            "perspicacious",
            "cacophony",
            "obfuscate",
            "ephemeral",
            "serendipity",
            "eloquent",
            "ambiguous",
            "ubiquitous",
            "meticulous",
            "pragmatic"
        ]
        let index = Int.random(in: 0..<words.count)
        return words[index]
    }
}

/// Session statistics for challenge tracking.
struct SessionStats: Codable {
    let score: Int
    let accuracy: Double  // 0.0 to 1.0
    let wordsLearned: Int
    let wordsMastered: Int
    let levelReached: Int
    let bestCombo: Int
    let timestamp: Date
    
    // Class property to track last session
    static var lastScore: Int?
    static var lastAccuracy: Double?
    static var lastLevelReached: Int?
}
