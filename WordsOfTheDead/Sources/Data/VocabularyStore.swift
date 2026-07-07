import Foundation

/// Loads and merges the parsed vocabulary list with the hand-authored fun definitions and
/// synonym sets.
///
/// `allWords` is the full ~1000-word pool (used to build realistic distractor choices),
/// while `playableWords` is the subset that has a fun definition — questions are drawn
/// from this set so every correct answer can reveal an interesting definition.
final class VocabularyStore {
    let allWords: [VocabWord]
    let playableWords: [VocabWord]
    let synonymWords: [VocabWord]

    private let synonymMap: [String: SynonymEntry]

    init() {
        let entries = VocabularyStore.loadVocab()
        let funMap = VocabularyStore.loadFunDefinitions()
        let synonymEntries = VocabularyStore.loadSynonymEntries()
        let synonymMap = synonymEntries.reduce(into: [String: SynonymEntry]()) { map, entry in
            let key = entry.word.lowercased()
            if let existing = map[key] {
                map[key] = SynonymEntry(
                    word: existing.word,
                    synonyms: Array(Set(existing.synonyms + entry.synonyms)).sorted(),
                    related: Array(Set(existing.related + entry.related)).sorted()
                )
            } else {
                map[key] = entry
            }
        }
        self.synonymMap = synonymMap

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
        synonymWords = playableWords.filter { synonymMap[$0.key] != nil }
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

    struct SynonymEntry {
        let word: String
        let synonyms: [String]
        let related: [String]
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

    private static func loadSynonymEntries() -> [SynonymEntry] {
        guard let url = Bundle.main.url(forResource: "synonym-words", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8)
        else { return [] }

        var entries: [SynonymEntry] = []
        for rawLine in text.split(whereSeparator: \.isNewline) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }

            let parts = line.components(separatedBy: "||")
            let left = parts.first ?? ""
            let right = parts.dropFirst().first ?? ""

            let leftParts = left.split(separator: "|").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            guard let word = leftParts.first, leftParts.count >= 5 else { continue }

            let synonyms = Array(leftParts.dropFirst())
            let related = right.split(separator: "|").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            entries.append(SynonymEntry(word: String(word), synonyms: synonyms, related: related))
        }
        return entries
    }

    func synonymEntry(for word: VocabWord) -> SynonymEntry? {
        synonymMap[word.key]
    }
}
