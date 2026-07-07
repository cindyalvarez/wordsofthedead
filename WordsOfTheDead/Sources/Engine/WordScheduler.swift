import Foundation

/// Chooses which word to present next using spaced repetition, and records outcomes.
///
/// Selection priority:
///  1. A word the player just missed this session, re-queued to reappear a few spawns later.
///  2. A word that is "due" for review (most overdue first) — resurfaces struggling words.
///  3. A brand-new word (mixed in so the player keeps learning vocabulary).
///  4. Fallback: the word that will be due soonest, so play never stalls.
@MainActor
final class WordScheduler {
    private let words: [VocabWord]
    private let byID: [String: VocabWord]
    private(set) var profile: [String: WordProgress]

    /// Words missed this session, with a countdown of spawns until they reappear.
    private var requeue: [(id: String, countdown: Int)] = []
    private var lastServedID: String?

    /// Probability of introducing a new word when reviews are also available.
    private let newWordChance = 0.35

    /// Highest difficulty tier currently allowed for *new* word introductions. The engine
    /// raises this as the player levels up so easier words are taught first.
    var unlockedTier: Int = 0

    init(words: [VocabWord]) {
        self.words = words
        self.byID = Dictionary(uniqueKeysWithValues: words.map { ($0.key, $0) })
        self.profile = LearningStore.load()
    }

    private func progress(for word: VocabWord) -> WordProgress {
        profile[word.key] ?? WordProgress()
    }

    // MARK: - Selection

    func nextWord(forLevel level: Int, eligible: (VocabWord) -> Bool = { _ in true }) -> VocabWord? {
        guard !words.isEmpty else { return nil }

        // Age the in-session re-queue; serve any word whose countdown has elapsed.
        for i in requeue.indices { requeue[i].countdown -= 1 }
        if let readyIdx = requeue.firstIndex(where: { $0.countdown <= 0 && byID[$0.id].map(eligible) == true }) {
            let id = requeue.remove(at: readyIdx).id
            if let word = byID[id], word.minLevel <= level {
                lastServedID = id
                return word
            }
        }

        let now = Date()
        let eligibleWords = words.filter { eligible($0) }
        guard !eligibleWords.isEmpty else { return nil }

        // Filter words by: tier gating, unseen/due status, AND level gating (minLevel <= current level)
        let unseen = eligibleWords.filter {
            profile[$0.key] == nil && $0.key != lastServedID && $0.tier <= unlockedTier && $0.minLevel <= level
        }
        let due = eligibleWords
            .filter { w in
                guard let p = profile[w.key] else { return false }
                return p.dueAt <= now && w.key != lastServedID && w.minLevel <= level
            }
            .sorted { (profile[$0.key]?.dueAt ?? now) < (profile[$1.key]?.dueAt ?? now) }

        let chosen: VocabWord
        if !due.isEmpty && (unseen.isEmpty || Double.random(in: 0..<1) >= newWordChance) {
            // Prefer the most-overdue review, with a little randomness among the oldest few.
            let head = Array(due.prefix(5))
            chosen = head.randomElement() ?? due[0]
        } else if let fresh = easiestUnseen(from: unseen) {
            chosen = fresh
        } else if let soonest = eligibleWords
            .filter({ $0.key != lastServedID && $0.minLevel <= level })
            .min(by: { progress(for: $0).dueAt < progress(for: $1).dueAt }) {
            chosen = soonest
        } else {
            chosen = eligibleWords.filter({ $0.minLevel <= level }).randomElement()!
        }

        lastServedID = chosen.key
        return chosen
    }

    /// Among unseen candidates, pick from the easiest tier present (with a little
    /// randomness) so high-utility, simpler words are taught first.
    private func easiestUnseen(from unseen: [VocabWord]) -> VocabWord? {
        guard let minTier = unseen.map({ $0.tier }).min() else { return nil }
        return unseen.filter { $0.tier == minTier }.randomElement()
    }

    /// A word the player has struggled with — used to build "boss review" rounds.
    /// Prefers words answered wrong / not yet known, most overdue first. Returns nil only
    /// if the player has no review history yet.
    func reviewWord(forLevel level: Int, eligible: (VocabWord) -> Bool = { _ in true }) -> VocabWord? {
        let now = Date()
        let pool = words.filter { w in
            guard eligible(w), let p = profile[w.key], w.key != lastServedID else { return false }
            return (p.stage != .known || p.wrong > 0) && w.minLevel <= level
        }
        guard !pool.isEmpty else { return nil }
        let sorted = pool.sorted { (profile[$0.key]?.dueAt ?? now) < (profile[$1.key]?.dueAt ?? now) }
        let chosen = Array(sorted.prefix(6)).randomElement() ?? sorted[0]
        lastServedID = chosen.key
        return chosen
    }

    /// Whether the player has any words eligible for a boss review round.
    var hasReviewableWords: Bool {
        words.contains { w in
            guard let p = profile[w.key] else { return false }
            return p.stage != .known || p.wrong > 0
        }
    }

    // MARK: - Outcomes

    /// Records the final outcome for a word (killed = correct, timed out = wrong) and
    /// persists the updated profile.
    func record(_ word: VocabWord, correct: Bool) {
        var p = progress(for: word)
        p.record(correct: correct)
        profile[word.key] = p
        LearningStore.save(profile)
    }

    /// Marks that the player just answered this word wrong, so it reappears 2–3 spawns
    /// later within the session (in-session reinforcement). Enqueues at most once.
    func requeueSoon(_ word: VocabWord) {
        guard !requeue.contains(where: { $0.id == word.key }) else { return }
        requeue.append((id: word.key, countdown: Int.random(in: 2...3)))
    }

    // MARK: - Stats

    var masteredCount: Int {
        profile.values.filter { $0.stage == .known }.count
    }

    var totalWords: Int { words.count }

    func stage(for word: VocabWord) -> MasteryStage {
        progress(for: word).stage
    }
}
