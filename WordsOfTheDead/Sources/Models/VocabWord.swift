import Foundation

/// A single vocabulary entry, optionally enriched with a hand-authored "fun" definition.
struct VocabWord: Identifiable, Hashable {
    let id = UUID()
    let word: String
    let pos: String
    let shortDefinition: String
    let funDefinition: String?
    /// Minimum level at which this word can appear (for level-gated vocabulary tiers).
    let minLevel: Int
    /// Bundled tier from the data (if available); overrides computed tier.
    let bundledTier: Int?

    /// Stable key for persistence/scheduling (the UUID is regenerated on each load).
    var key: String { word.lowercased() }

    /// Expands the terse part-of-speech code into a readable label.
    var displayPos: String {
        switch pos {
        case "n": return "noun"
        case "v": return "verb"
        case "adj": return "adjective"
        case "adv": return "adverb"
        default: return pos
        }
    }

    /// Rough difficulty proxy. No frequency corpus is bundled, so longer and more
    /// syllable-heavy words are treated as harder; this lets the scheduler teach easier,
    /// higher-utility words first and unlock harder ones as the player levels up.
    var difficulty: Int {
        word.count + VocabWord.estimateSyllables(word) * 2
    }

    /// Difficulty tier 0 (easiest) … 3 (hardest), used to gate which new words appear.
    /// Uses bundled tier if available, otherwise computes from word properties.
    var tier: Int {
        bundledTier ?? computedTier
    }

    /// Computed tier based on word difficulty (used when bundledTier is nil).
    private var computedTier: Int {
        switch difficulty {
        case ..<10: return 0
        case ..<14: return 1
        case ..<18: return 2
        default:    return 3
        }
    }

    /// Cheap syllable estimate: counts groups of adjacent vowels (a usable proxy without
    /// a pronunciation dictionary).
    static func estimateSyllables(_ word: String) -> Int {
        let vowels = Set("aeiouy")
        var count = 0
        var prevVowel = false
        for ch in word.lowercased() {
            let isVowel = vowels.contains(ch)
            if isVowel && !prevVowel { count += 1 }
            prevVowel = isVowel
        }
        return max(1, count)
    }
}

/// One question shown beneath a zombie. Definition and reverse-definition rounds have
/// four candidate choices; synonym rounds have six choices with multiple correct answers;
/// fill-in-the-blank rounds have two candidate words.
struct Question {
    let word: VocabWord
    let choices: [String]
    let correctIndex: Int
    let correctIndices: Set<Int>
}

/// Which gameplay style a zombie uses. Levels rotate through the four kinds in order.
enum RoundKind {
    case definition         // match the word (shown) to its definition (press SPACE)
    case synonym            // click all synonyms
    case reverseDefinition  // match the definition (shown) to its word (press SPACE)
    case fillBlank          // complete the sentence (press F or J)
}

/// A zombie currently on screen, with its own falling state and question.
struct ActiveZombie: Identifiable {
    let id = UUID()
    let question: Question
    let kind: RoundKind
    /// Text displayed on the zombie itself: the vocabulary word (definition rounds) or
    /// the sentence with a blank (fill-in-the-blank rounds).
    let prompt: String
    var progress: Double = 0
    var speed: Double
    let variant: Int
    let lane: Int
    var currentChoiceIndex: Int
    var selectedChoiceIndices: Set<Int> = []
    var wrongChoiceIndices: Set<Int> = []
    var wrong: Bool = false
    var isExploding: Bool = false
}

extension Array {
    /// Bounds-checked subscript that returns nil instead of crashing.
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
