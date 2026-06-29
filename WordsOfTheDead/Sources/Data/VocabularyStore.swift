import Foundation

/// Loads and merges the parsed vocabulary list with the hand-authored fun definitions.
///
/// `allWords` is the full ~1000-word pool (used to build realistic distractor choices),
/// while `playableWords` is the subset that has a fun definition — questions are drawn
/// from this set so every correct answer can reveal an interesting definition.
final class VocabularyStore {
    let allWords: [VocabWord]
    let playableWords: [VocabWord]

    init() {
        let entries = VocabularyStore.loadVocab()
        let funMap = VocabularyStore.loadFunDefinitions()

        allWords = entries.map { entry in
            VocabWord(
                word: entry.word,
                pos: entry.pos,
                shortDefinition: entry.shortDefinition,
                funDefinition: funMap[entry.word.lowercased()],
                minLevel: entry.minLevel ?? 1,
                bundledTier: entry.tier
            )
        }
        playableWords = allWords.filter { $0.funDefinition != nil }
    }

    // MARK: - Loading

    private struct RawVocabEntry: Decodable {
        let word: String
        let pos: String
        let shortDefinition: String
        let minLevel: Int?
        let tier: Int?
    }

    private struct FunDefinitionsFile: Decodable {
        let definitions: [FunDefinition]
    }

    private struct FunDefinition: Decodable {
        let word: String
        let funDefinition: String
    }

    private static func loadVocab() -> [RawVocabEntry] {
        guard let url = Bundle.main.url(forResource: "vocab", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([RawVocabEntry].self, from: data)
        else { return [] }
        return entries
    }

    private static func loadFunDefinitions() -> [String: String] {
        guard let url = Bundle.main.url(forResource: "fun_definitions", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(FunDefinitionsFile.self, from: data)
        else { return [:] }

        var map: [String: String] = [:]
        for def in file.definitions where !def.funDefinition.isEmpty {
            map[def.word.lowercased()] = def.funDefinition
        }
        // Layer QA corrections (from --qa review mode) on top of the bundled defaults.
        for (word, corrected) in FunDefinitionOverrides.load() {
            map[word.lowercased()] = corrected
        }
        return map
    }
}
