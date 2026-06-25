import Foundation

/// How well a word has been learned, derived from its Leitner box.
enum MasteryStage: String, Codable {
    case new        // never attempted
    case learning   // seen, but not yet promoted to a long review interval
    case known      // answered correctly enough times, spaced apart

    var label: String {
        switch self {
        case .new: return "New"
        case .learning: return "Learning"
        case .known: return "Known ✓"
        }
    }
}

/// Per-word spaced-repetition state (a Leitner-style box plus due date and tallies).
/// Persisted between sessions so the game can resurface struggling words and rest
/// mastered ones.
struct WordProgress: Codable {
    var box: Int = 0
    var correct: Int = 0
    var wrong: Int = 0
    var streak: Int = 0
    /// When this word should next be reviewed.
    var dueAt: Date = .distantPast
    var lastSeen: Date?

    /// Box at or above which a word counts as "known".
    static let masteredBox = 4
    static let maxBox = 5

    /// Leitner review intervals per box (seconds). Early boxes are short so a word in
    /// active learning comes back within the same session; later boxes span days.
    static let intervals: [TimeInterval] = [
        0,        // box 0: due immediately
        60,       // box 1: 1 minute
        600,      // box 2: 10 minutes
        86_400,   // box 3: 1 day
        259_200,  // box 4: 3 days
        604_800   // box 5: 7 days
    ]

    var attempts: Int { correct + wrong }

    var stage: MasteryStage {
        if attempts == 0 { return .new }
        return box >= WordProgress.masteredBox ? .known : .learning
    }

    var isDue: Bool { dueAt <= Date() }

    private func interval(for box: Int) -> TimeInterval {
        let clamped = max(0, min(box, WordProgress.intervals.count - 1))
        return WordProgress.intervals[clamped]
    }

    /// Records an answer and reschedules: a correct answer promotes the box (longer
    /// interval), a wrong answer demotes it (sooner review).
    mutating func record(correct: Bool, at now: Date = Date()) {
        lastSeen = now
        if correct {
            self.correct += 1
            streak += 1
            box = min(WordProgress.maxBox, box + 1)
        } else {
            wrong += 1
            streak = 0
            box = max(0, box - 1)
        }
        dueAt = now.addingTimeInterval(interval(for: box))
    }
}
