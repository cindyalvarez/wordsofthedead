import Foundation
import SwiftUI

/// Drives the game loop: level progression, spawning zombies (one or, from level 5, two
/// at a time), advancing them, handling guesses, lives/streaks, and the reveal.
@MainActor
final class GameEngine: ObservableObject {

    enum Phase {
        case playerSelect, cutscene, start, levelIntro, playing, revealing, gameOver
    }

    @Published private(set) var phase: Phase = .playerSelect
    @Published private(set) var zombies: [ActiveZombie] = []
    @Published private(set) var zombiesKilled: Int = 0
    @Published private(set) var lives: Int = 1
    @Published private(set) var level: Int = 1
    @Published private(set) var revealWord: VocabWord?
    @Published private(set) var revealStage: MasteryStage?
    @Published private(set) var showStreakBanner: Bool = false
    @Published private(set) var masteredCount: Int = 0

    // Scoring (suggestion #8).
    @Published private(set) var score: Int = 0
    @Published private(set) var comboMultiplier: Double = 1.0

    // End-of-run summary (suggestion #9).
    @Published private(set) var runCorrect: Int = 0
    @Published private(set) var runMissed: Int = 0
    @Published private(set) var runNewlyMastered: Int = 0
    @Published private(set) var runBestStreak: Int = 0

    // Daily goal / streak (suggestion #7).
    @Published private(set) var todayCount: Int = 0
    @Published private(set) var dayStreak: Int = 0

    // Pause (suggestion #17) and boss rounds (suggestion #13).
    @Published private(set) var isPaused: Bool = false
    @Published private(set) var isBossLevel: Bool = false

    // Saved-player progress: the active player's display name (empty until one is chosen).
    @Published private(set) var currentPlayerName: String = ""

    // Engagement features: streak metrics, daily challenges, last session stats.
    @Published private(set) var metrics: StreakMetrics = StreakMetrics(
        currentStreak: 0,
        longestStreak: 0,
        breakInStreak: 0,
        daysUntilMilestone: 7,
        nextMilestone: 7,
        streakAtRisk: false,
        timeUntilDeadline: 0,
        todayProgress: 0,
        todayGoal: 20
    )
    @Published private(set) var dailyChallenges: [DailyChallenge] = []
    @Published private(set) var lastSessionStats: SessionStats?

    private var missedKeysThisRun: Set<String> = []

    /// Words from zombies that were still falling when a level ended. They are the
    /// "upcoming" words the player saw previewed on the second/third zombie, so they are
    /// played first in the next level instead of being discarded.
    private var carryOverWords: [VocabWord] = []

    private let store = VocabularyStore()
    private lazy var generator = QuestionGenerator(store: store)

    // Per-player progress: the scheduler (learning profile) and daily tracker are (re)created
    // when a player is selected, so each player keeps their own mastery and streak history.
    private var scheduler: WordScheduler!
    private var daily: DailyGoalTracker!

    // Saved-player roster.
    private var roster = PlayerStore.Roster()
    private(set) var currentPlayer: Player?

    init() {
        roster = PlayerStore.load()
        // If players already exist, any pre-player (legacy) progress was already claimed by
        // the first player. Consume the legacy files and lock the flag so a later "first"
        // player (e.g. after a roster reset) can never re-inherit that old progress.
        if !roster.players.isEmpty && !roster.legacyMigrated {
            LearningStore.consumeLegacy()
            DailyGoalStore.consumeLegacy()
            roster.legacyMigrated = true
            PlayerStore.save(roster)
        }
    }

    /// Saved players, most recently played first.
    var savedPlayers: [Player] { roster.players.sorted { $0.lastPlayedAt > $1.lastPlayedAt } }
    
    /// All saved players (alias for UI convenience).
    var players: [Player] { savedPlayers }

    /// The player who was active last launch, if any.
    var lastPlayer: Player? {
        guard let id = roster.lastPlayerID else { return nil }
        return roster.players.first { $0.id == id }
    }

    var hasSavedPlayers: Bool { !roster.players.isEmpty }

    var totalWords: Int { store.playableWords.count }
    var dailyGoal: Int { daily?.goal ?? 20 }
    var totalWordsMastered: Int { scheduler?.masteredCount ?? 0 }
    var wordsMasteredToday: Int { daily?.todayCount ?? 0 }
    var levelsPlayedTotal: Int { currentPlayer?.bestLevel ?? 1 }
    
    func recentDays(_ days: Int = 7) -> [DayActivity] { daily?.recentDays(days) ?? [] }
    var runAccuracy: Double {
        let attempts = runCorrect + runMissed
        return attempts == 0 ? 0 : Double(runCorrect) / Double(attempts)
    }

    private var timer: Timer?
    private let tickInterval = 0.05
    private var revealTask: DispatchWorkItem?
    private var streakBannerTask: DispatchWorkItem?
    private var levelIntroTask: DispatchWorkItem?
    private var streak = 0
    private var wordsThisLevel = 0

    // Tuning.
    private let baseSpeed = 0.001089
    private let maxSpeed = 0.04
    private let startingLives = 1
    private let streakForExtraLife = 5
    private let revealDuration = 3.0
    private let levelIntroDuration = 1.8
    private let standardWordsPerLevel = 10
    
    // Zombie spawning tiers: zombies are added at each milestone level
    private let twoZombieLevel = 1
    private let threeZombieLevel = 3
    private let fourZombieLevel = 5
    
    // Second zombie spawn point: starts at 55% on level 1, then 3% earlier each level
    private let secondZombieTrigger = 0.55
    private let secondZombieEarlierPerLevel = 0.03
    private let secondZombieTriggerFloor = 0.2
    
    // Third zombie spawn point: 55% on level 3, then 3% earlier each level
    private let thirdZombieTrigger = 0.55
    private let thirdZombieTriggerFloor = 0.2
    
    // Fourth zombie spawn point: 55% on level 5, then 3% earlier each level
    private let fourthZombieTrigger = 0.55
    private let fourthZombieTriggerFloor = 0.2

    // Scoring (#8).
    private let basePoints = 100
    private let comboStep = 0.25
    private let maxCombo = 5.0

    // Boss review rounds (#13): every Nth level draws only from struggling words and falls
    // faster — but only once the player has words worth reviewing. Boss levels coincide
    // with "sf-" background images (multiples of 5).
    private let bossInterval = 5
    private let bossSpeedMultiplier = 1.35

    // Adaptive speed (#12): recent outcomes nudge fall speed up (doing well) or down
    // (struggling), keeping the player in a productive-difficulty zone.
    private var recentOutcomes: [Bool] = []
    private let adaptiveWindow = 8
    private let adaptiveMinFactor = 0.75
    private let adaptiveMaxFactor = 1.35

    /// In test mode, only one word is needed to advance to the next level.
    private var testMode = false
    private var wordsPerLevel: Int { testMode ? 1 : standardWordsPerLevel }

    private let choiceRotationInterval = 1.2
    private var ticksSinceRotation = 0

    var hasContent: Bool { !store.playableWords.isEmpty }

    /// The zombie the player is currently answering: the one closest to the bottom.
    var leadZombie: ActiveZombie? {
        guard let idx = leadIndex else { return nil }
        return zombies[idx]
    }

    private var leadIndex: Int? {
        guard !zombies.isEmpty else { return nil }
        var idx = 0
        for i in zombies.indices where zombies[i].progress > zombies[idx].progress { idx = i }
        return idx
    }

    // MARK: - Players (saved progress)

    /// Creates a new player (or continues an existing one if the name matches), then moves
    /// to the start screen. Used by the "new player" name entry.
    func createPlayer(named rawName: String) {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let id = PlayerStore.slug(for: name)
        if let existing = roster.players.first(where: { $0.id == id }) {
            activate(existing)
        } else {
            // Only the very first player ever created inherits pre-player (legacy) progress.
            let isFirstPlayer = roster.players.isEmpty && !roster.legacyMigrated
            activate(Player(id: id, name: name), migrateLegacy: isFirstPlayer)
        }
    }

    /// Continues an existing saved player.
    func continueAs(_ player: Player) {
        activate(player)
    }

    /// Returns to the player-selection screen (e.g. to switch players).
    func switchPlayer() {
        stopTimers()
        zombies = []
        isPaused = false
        roster = PlayerStore.load()
        phase = .playerSelect
    }

    /// Activates a player: points the per-player stores at their files, loads their learning
    /// profile and daily history, records them as last-played, and shows the start screen.
    private func activate(_ player: Player, migrateLegacy: Bool = false) {
        LearningStore.playerID = player.id
        DailyGoalStore.playerID = player.id
        if migrateLegacy {
            LearningStore.migrateLegacyIfNeeded()
            DailyGoalStore.migrateLegacyIfNeeded()
            roster.legacyMigrated = true
        }
        scheduler = WordScheduler(words: store.playableWords)
        daily = DailyGoalTracker()
        masteredCount = scheduler.masteredCount

        var updated = player
        updated.lastPlayedAt = Date()
        upsert(updated)
        roster.lastPlayerID = updated.id
        PlayerStore.save(roster)
        currentPlayer = updated
        currentPlayerName = updated.name

        refreshDailyStats()
        
        // Load engagement features for the selected player
        let sessionIndex = player.gamesPlayed
        dailyChallenges = DailyChallengeGenerator.generateChallenges(
            yesterdayScore: player.bestScore > 0 ? player.bestScore : nil,
            streakLength: daily?.currentStreak ?? 0,
            wordsLearned: scheduler.masteredCount,
            totalWords: store.playableWords.count,
            sessionIndex: sessionIndex
        )
        updateMetrics()
        
       // Show cutscene only for new players; returning players go straight to start.
       phase = updated.hasWatchedCutscene ? .start : .cutscene
    }

    private func upsert(_ player: Player) {
        if let idx = roster.players.firstIndex(where: { $0.id == player.id }) {
            roster.players[idx] = player
        } else {
            roster.players.append(player)
        }
    }

    /// Records the result of a finished run into the active player's saved best progress.
    private func recordRunResult() {
        guard var player = currentPlayer else { return }
        player.bestLevel = max(player.bestLevel, level)
        player.bestScore = max(player.bestScore, score)
        player.gamesPlayed += 1
        player.lastPlayedAt = Date()
        upsert(player)
        roster.lastPlayerID = player.id
        PlayerStore.save(roster)
        currentPlayer = player
    }

    // MARK: - Game lifecycle

    func startGame(testMode: Bool = false) {
        guard scheduler != nil else { return }
        self.testMode = testMode
        zombiesKilled = 0
        lives = startingLives
        streak = 0
        level = 1
        wordsThisLevel = 0
        zombies = []
        showStreakBanner = false
        masteredCount = scheduler.masteredCount
        score = 0
        comboMultiplier = 1.0
        runCorrect = 0
        runMissed = 0
        runNewlyMastered = 0
        runBestStreak = 0
        missedKeysThisRun = []
        carryOverWords = []
        recentOutcomes = []
        isPaused = false
        refreshDailyStats()
        startTimer()
        beginLevelIntro()
    }

    func markCutsceneWatched() {
       guard var player = currentPlayer else { return }
       player.hasWatchedCutscene = true
       upsert(player)
       currentPlayer = player
       startGame()
    }

    private func refreshDailyStats() {
        todayCount = daily?.todayCount ?? 0
        dayStreak = daily?.currentStreak ?? 0
    }

    // MARK: - Pause

    /// Toggles pause (suggestion #17). Only meaningful during active play.
    func togglePause() {
        guard phase == .playing else { return }
        isPaused.toggle()
    }

    /// Definition and reverse-definition rounds: the player presses SPACE while the shown
    /// choice (definition, or word) is the correct one.
    func guessCurrent() {
        guard phase == .playing, !isPaused, let idx = leadIndex,
              zombies[idx].kind == .definition || zombies[idx].kind == .reverseDefinition else { return }
        resolveLead(at: idx, correct: zombies[idx].currentChoiceIndex == zombies[idx].question.correctIndex)
    }

    /// Synonym rounds: each correct click locks in one synonym; all four must be selected.
    func answerSynonymChoice(at choiceIndex: Int) {
        guard phase == .playing, !isPaused, let idx = leadIndex,
              zombies[idx].kind == .synonym else { return }

        let question = zombies[idx].question
        guard choiceIndex >= 0, choiceIndex < question.choices.count,
              !zombies[idx].selectedChoiceIndices.contains(choiceIndex) else { return }

        if question.correctIndices.contains(choiceIndex) {
            zombies[idx].selectedChoiceIndices.insert(choiceIndex)
            if zombies[idx].selectedChoiceIndices.isSuperset(of: question.correctIndices) {
                resolveLead(at: idx, correct: true)
            } else {
                objectWillChange.send()
            }
        } else {
            zombies[idx].wrong = true
            zombies[idx].wrongChoiceIndices.insert(choiceIndex)
            zombies[idx].progress = min(1, zombies[idx].progress + 0.08)
            zombies[idx].speed = min(maxSpeed, zombies[idx].speed * 1.4)
            objectWillChange.send()
            if zombies[idx].progress >= 1 {
                zombieReachedBottom(at: idx)
            }
        }
    }

    /// Fill-in-the-blank rounds: the player presses F (left word) or J (right word) to
    /// complete the sentence.
    func answerFillBlank(left: Bool) {
        guard phase == .playing, !isPaused, let idx = leadIndex,
              zombies[idx].kind == .fillBlank else { return }
        let chosenIndex = left ? 0 : 1
        resolveLead(at: idx, correct: chosenIndex == zombies[idx].question.correctIndex)
    }
    
    /// Definition/reverse-definition rounds: player presses J to cycle through choices.
    func advanceCurrentChoice() {
        guard phase == .playing, !isPaused, let idx = leadIndex,
              zombies[idx].kind == .definition || zombies[idx].kind == .reverseDefinition else { return }
        let count = zombies[idx].question.choices.count
        guard count > 0 else { return }
        zombies[idx].currentChoiceIndex = (zombies[idx].currentChoiceIndex + 1) % count
    }

    /// Click-to-answer: jump to a specific choice and resolve immediately.
    func guessChoice(at choiceIndex: Int) {
        guard phase == .playing, !isPaused, let idx = leadIndex,
              zombies[idx].kind == .definition || zombies[idx].kind == .reverseDefinition else { return }
        let count = zombies[idx].question.choices.count
        guard choiceIndex >= 0, choiceIndex < count else { return }
        zombies[idx].currentChoiceIndex = choiceIndex
        resolveLead(at: idx, correct: choiceIndex == zombies[idx].question.correctIndex)
    }

    private func resolveLead(at idx: Int, correct: Bool) {
        let zombie = zombies[idx]
        if correct {
            zombiesKilled += 1
            streak += 1
            runBestStreak = max(runBestStreak, streak)
            comboMultiplier = min(maxCombo, 1.0 + Double(streak) * comboStep)
            // Score: base + a speed bonus for killing the zombie high up, times the combo.
            let speedBonus = Int((1.0 - zombie.progress) * Double(basePoints))
            score += Int(Double(basePoints + speedBonus) * comboMultiplier)
            if streak % streakForExtraLife == 0 {
                lives += 1
                flashStreakBanner()
            }
            recordOutcome(zombie.question.word, correct: true)
            // Trigger explosion animation and sound; zombie will be removed after animation completes
            SoundManager.shared.playExplosion()
            zombies[idx].isExploding = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let removeIdx = self.zombies.firstIndex(where: { $0.id == zombie.id }) {
                    self.zombies.remove(at: removeIdx)
                }
            }
            // Spawn the next zombie immediately so it starts at the top without waiting
            // for the reveal to finish. Only spawn if the level isn't about to end and
            // there are no other zombies already in play.
            let isLastWordOfLevel = (wordsThisLevel + 1) >= wordsPerLevel
            if !isLastWordOfLevel && zombies.filter({ !$0.isExploding }).count <= 1 {
                spawnZombie()
            }
            reveal(zombie.question.word)
        } else {
            streak = 0
            comboMultiplier = 1.0
            // First wrong guess on this zombie: resurface the word later this session.
            if !zombies[idx].wrong {
                scheduler.requeueSoon(zombie.question.word)
            }
            // Wrong answer: this zombie lurches forward and speeds up.
            zombies[idx].wrong = true
            zombies[idx].progress = min(1, zombies[idx].progress + 0.08)
            zombies[idx].speed = min(maxSpeed, zombies[idx].speed * 1.4)
            if zombies[idx].progress >= 1 {
                zombieReachedBottom(at: idx)
            }
        }
    }

    /// Records a final outcome for a word: updates spaced repetition, daily-goal practice
    /// count, run tallies, adaptive-speed window, and newly-mastered count.
    private func recordOutcome(_ word: VocabWord, correct: Bool) {
        let wasKnown = scheduler.stage(for: word) == .known
        scheduler.record(word, correct: correct)
        if !wasKnown && scheduler.stage(for: word) == .known {
            runNewlyMastered += 1
        }
        masteredCount = scheduler.masteredCount

        if correct {
            runCorrect += 1
        } else {
            runMissed += 1
            missedKeysThisRun.insert(word.key)
        }

        recentOutcomes.append(correct)
        if recentOutcomes.count > adaptiveWindow { recentOutcomes.removeFirst() }

        daily.recordPractice()
        refreshDailyStats()
    }

    // MARK: - Levels

    private func levelSpeed() -> Double {
        // Base curve: constant within a level, +1% per level.
        let base = min(maxSpeed, baseSpeed * pow(1.01, Double(level - 1)))
        var speed = base * adaptiveFactor()
        if isBossLevel { speed *= bossSpeedMultiplier }
        return min(maxSpeed, speed)
    }

    /// Rubber-banding factor from recent accuracy (#12): a hot streak speeds zombies up,
    /// a cold streak slows them down, keeping difficulty near the player's ability.
    private func adaptiveFactor() -> Double {
        guard !recentOutcomes.isEmpty else { return 1.0 }
        let accuracy = Double(recentOutcomes.filter { $0 }.count) / Double(recentOutcomes.count)
        // Map accuracy 0…1 onto [min…max], centered so ~0.5 accuracy ≈ 1.0x.
        let factor = adaptiveMinFactor + (adaptiveMaxFactor - adaptiveMinFactor) * accuracy
        return min(adaptiveMaxFactor, max(adaptiveMinFactor, factor))
    }

    private var maxConcurrentZombies: Int {
        if level >= fourZombieLevel { return 4 }
        if level >= threeZombieLevel { return 3 }
        if level >= twoZombieLevel { return 2 }
        return 1
    }

    /// Progress at which the second zombie spawns: 55% on level 1, then 3% earlier per
    /// level (52% at L2, 49% at L3, ...), floored so it never spawns at the very top.
    private var secondZombieTriggerForLevel: Double {
        let earlier = Double(max(0, level - twoZombieLevel)) * secondZombieEarlierPerLevel
        return max(secondZombieTriggerFloor, secondZombieTrigger - earlier)
    }
    
    /// Progress at which the third zombie spawns: 55% on level 3, then 3% earlier per
    /// level (52% at L4, 49% at L5, ...), floored so it never spawns at the very top.
    private var thirdZombieTriggerForLevel: Double {
        guard level >= threeZombieLevel else { return Double.infinity }
        let earlier = Double(max(0, level - threeZombieLevel)) * secondZombieEarlierPerLevel
        return max(thirdZombieTriggerFloor, thirdZombieTrigger - earlier)
    }
    
    /// Progress at which the fourth zombie spawns: 55% on level 5, then 3% earlier per
    /// level (52% at L6, 49% at L7, ...), floored so it never spawns at the very top.
    private var fourthZombieTriggerForLevel: Double {
        guard level >= fourZombieLevel else { return Double.infinity }
        let earlier = Double(max(0, level - fourZombieLevel)) * secondZombieEarlierPerLevel
        return max(fourthZombieTriggerFloor, fourthZombieTrigger - earlier)
    }

    private func beginLevelIntro() {
        phase = .levelIntro
        isPaused = false
        zombies = []
        revealTask?.cancel()
        revealWord = nil

        // Unlock harder word tiers as the player climbs (#11): tier 0 at L1-2, then one
        // more tier every two levels.
        scheduler.unlockedTier = min(3, (level - 1) / 2)

        // Boss review levels (#13): every Nth level (multiples of 5). 
        // Boss levels use faster speeds and draw from struggling words once available.
        isBossLevel = !testMode && level % bossInterval == 0

        let task = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.phase = .playing
            self.wordsThisLevel = 0
            self.spawnZombie()
        }
        levelIntroTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + levelIntroDuration, execute: task)
    }

    /// Records that one word has been dealt with; advances the level after 20.
    /// Returns true if a level transition was started.
    private func recordWordResolved() -> Bool {
        wordsThisLevel += 1
        if wordsThisLevel >= wordsPerLevel {
            // Zombies still on screen were previewing the upcoming words; carry them into
            // the next level so the word that naturally comes next is the one played next.
            carryOverWords = zombies.map { $0.question.word }
            level += 1
            beginLevelIntro()
            return true
        }
        return false
    }

    // MARK: - Spawning / resolution

    /// The gameplay style for the current level, rotating through the four kinds.
    private var roundKindForLevel: RoundKind {
        switch (level - 1) % 4 {
        case 0: return .definition
        case 1: return .synonym
        case 2: return .reverseDefinition
        default: return .fillBlank
        }
    }

    /// Player-facing instruction for the current level's challenge type, shown on the
    /// level intro screen.
    var levelInstruction: String {
        switch roundKindForLevel {
        case .definition:
            return "Match the WORD to its definition — press SPACE on the correct one."
        case .synonym:
            return "Click all 4 synonyms to defeat the zombie."
        case .reverseDefinition:
            return "Match the DEFINITION to its word — press SPACE on the correct one."
        case .fillBlank:
            return "Complete the sentence — click the correct word or press F / J."
        }
    }

    private func spawnZombie() {
        let kind = roundKindForLevel
        guard let word = takeNextWord(for: kind) else { return }
        let round = buildRound(for: word, kind: kind)
        let q = round.question
        let zombie = ActiveZombie(
            question: q,
            kind: round.kind,
            prompt: round.prompt,
            speed: levelSpeed(),
            variant: Int.random(in: 0..<ZombieKind.allCases.count),
            lane: Int.random(in: 0...2),
            currentChoiceIndex: Int.random(in: 0..<q.choices.count)
        )
        zombies.append(zombie)
        ticksSinceRotation = 0
    }

    /// The next word to show. Words from zombies that were still on screen when the level
    /// ended are played first (see `carryOverWords`), so the word a second/third zombie was
    /// previewing is the one that actually comes next. Boss levels otherwise draw from the
    /// struggling-words pool.
    private func takeNextWord(for kind: RoundKind) -> VocabWord? {
        let eligible: (VocabWord) -> Bool = { [store] word in
            switch kind {
            case .synonym:
                return store.synonymEntry(for: word) != nil
            default:
                return true
            }
        }

        if let carryIdx = carryOverWords.firstIndex(where: eligible) {
            return carryOverWords.remove(at: carryIdx)
        }
        if isBossLevel {
            return scheduler.reviewWord(forLevel: level, eligible: eligible)
                ?? scheduler.nextWord(forLevel: level, eligible: eligible)
        }
        return scheduler.nextWord(forLevel: level, eligible: eligible)
    }

    /// Builds the round for a word using the current level's challenge type.
    private func buildRound(for word: VocabWord, kind: RoundKind) -> Round {
        switch kind {
        case .definition:        return generator.makeDefinitionRound(for: word)
        case .synonym:           return generator.makeSynonymRound(for: word)
        case .reverseDefinition: return generator.makeReverseDefinitionRound(for: word)
        case .fillBlank:         return generator.makeFillBlankRound(for: word)
        }
    }

    private func reveal(_ word: VocabWord) {
        phase = .revealing
        revealWord = word
        revealStage = scheduler.stage(for: word)

        let task = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.revealWord = nil
            self.revealStage = nil
            if !self.recordWordResolved() {
                self.phase = .playing
                // Only spawn here if no zombie was pre-spawned at kill time.
                if self.zombies.isEmpty { self.spawnZombie() }
            }
        }
        revealTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + revealDuration, execute: task)
    }

    private func zombieReachedBottom(at index: Int) {
        guard zombies.indices.contains(index) else { return }
        let word = zombies[index].question.word
        zombies.remove(at: index)
        // Spaced-repetition: a timeout counts as a missed review (demotes the word).
        recordOutcome(word, correct: false)
        scheduler.requeueSoon(word)
        comboMultiplier = 1.0
        lives -= 1
        streak = 0
        if lives <= 0 {
            endGame()
            return
        }
        if !recordWordResolved() {
            if zombies.isEmpty { spawnZombie() }
        }
    }

    // MARK: - Timer loop

    private func startTimer() {
        timer?.invalidate()
        let timer = Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.advance() }
        }
        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func advance() {
        guard phase == .playing, !isPaused else { return }

        // Move every zombie; the first to reach the bottom costs a life.
        for i in zombies.indices {
            zombies[i].progress += zombies[i].speed
        }
        // Explicitly notify observers of changes to zombie positions
        objectWillChange.send()
        
        if let hit = zombies.firstIndex(where: { $0.progress >= 1 }) {
            zombieReachedBottom(at: hit)
            return
        }

        // Spawn new zombies when the lead zombie reaches the trigger point for each tier.
        // The trigger point moves 3% earlier each level within that tier.
        if zombies.count < maxConcurrentZombies,
           let lead = leadZombie {
            if zombies.count == 1 && lead.progress >= secondZombieTriggerForLevel {
                spawnZombie()
            } else if zombies.count == 2 && lead.progress >= thirdZombieTriggerForLevel {
                spawnZombie()
            } else if zombies.count == 3 && lead.progress >= fourthZombieTriggerForLevel {
                spawnZombie()
            }
        }

        // Auto-rotation disabled: definitions now only change when player presses J (advanceCurrentChoice)
        // rotateLeadChoice()
    }

    private func rotateLeadChoice() {
        guard let idx = leadIndex,
              zombies[idx].kind == .definition || zombies[idx].kind == .reverseDefinition else { return }
        ticksSinceRotation += 1
        guard Double(ticksSinceRotation) * tickInterval >= choiceRotationInterval else { return }
        ticksSinceRotation = 0
        let count = zombies[idx].question.choices.count
        guard count > 0 else { return }
        zombies[idx].currentChoiceIndex = (zombies[idx].currentChoiceIndex + 1) % count
    }

    private func flashStreakBanner() {
        streakBannerTask?.cancel()
        showStreakBanner = true
        let task = DispatchWorkItem { [weak self] in self?.showStreakBanner = false }
        streakBannerTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8, execute: task)
    }

    private func stopTimers() {
        timer?.invalidate()
        timer = nil
        revealTask?.cancel(); revealTask = nil
        levelIntroTask?.cancel(); levelIntroTask = nil
        streakBannerTask?.cancel(); streakBannerTask = nil
        showStreakBanner = false
        isPaused = false
    }

    private func endGame() {
        stopTimers()
        recordRunResult()
        
        // Create session stats for opening screen display
        let sessionStats = SessionStats(
            score: score,
            accuracy: runAccuracy,
            wordsLearned: zombiesKilled,
            wordsMastered: runNewlyMastered,
            levelReached: level,
            bestCombo: runBestStreak,
            timestamp: Date()
        )
        lastSessionStats = sessionStats
        
        // Update metrics after game
        updateMetrics()
        
        // Check for milestone achievements
        if dailyGoal > 0 && todayCount >= dailyGoal {
            let newStreak = daily?.currentStreak ?? 0
            if newStreak > 0 {
                let milestones = [7, 14, 30, 60, 100]
                if milestones.contains(newStreak) {
                    NotificationManager.shared.notifyMilestoneReached(newStreak)
                }
            }
        }
        
        // Check if streak at risk
        let progress = Double(todayCount) / Double(dailyGoal)
        if progress < 0.25 && progress > 0 {
            NotificationManager.shared.notifyStreakAtRisk()
        }
        
        phase = .gameOver
        zombies = []
    }
    
    /// Updates engagement metrics from daily goal tracker.
    private func updateMetrics() {
        guard let daily = daily else { return }
        let computed = daily.computeMetrics(todayProgress: todayCount)
        metrics = computed
    }
}
