import Foundation

/// One fun sentence under QA review.
struct FunSentenceItem: Identifiable {
    var id: String { word.lowercased() }
    let word: String
    let original: String
    /// The current text used in gameplay (a saved correction if one exists, else the original).
    var current: String
    /// Whether the reviewer has flagged this sentence as flawed.
    var flagged: Bool = false
    /// The editable suggested correction shown during the correction step.
    var suggestion: String = ""
}

/// Loads every fun sentence for the `--qa` review screen and saves reviewer corrections
/// back to the override store (which gameplay then picks up).
@MainActor
final class FunSentenceStore: ObservableObject {
    @Published var items: [FunSentenceItem] = []

    init() { load() }

    func load() {
        let overrides = FunDefinitionOverrides.load()
        var loaded: [FunSentenceItem] = []
        for def in Self.loadBundledDefinitions() where !def.funDefinition.isEmpty {
            let corrected = overrides[def.word.lowercased()]
            loaded.append(FunSentenceItem(
                word: def.word,
                original: def.funDefinition,
                current: corrected ?? def.funDefinition
            ))
        }
        items = loaded.sorted { $0.word.lowercased() < $1.word.lowercased() }
    }

    /// Saves the suggestions of every flagged item as corrections, then refreshes state.
    @discardableResult
    func saveCorrections() -> Int {
        var corrections: [String: String] = [:]
        for item in items where item.flagged {
            let text = item.suggestion.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty && text != item.current {
                corrections[item.word] = text
            }
        }
        guard !corrections.isEmpty else { return 0 }
        FunDefinitionOverrides.save(corrections)
        // Reflect the saved corrections in-memory.
        for i in items.indices {
            if let c = corrections[items[i].word] {
                items[i].current = c
                items[i].flagged = false
            }
        }
        return corrections.count
    }

    /// Produces a "best guess" cleanup of a flagged sentence: trims/normalizes spacing,
    /// capitalizes the first letter, and ensures it ends with terminal punctuation.
    static func suggestCorrection(for sentence: String, word: String) -> String {
        var text = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
        // Collapse runs of whitespace.
        while text.contains("  ") { text = text.replacingOccurrences(of: "  ", with: " ") }
        // Tidy spacing before punctuation.
        for p in [".", ",", "!", "?", ";", ":"] {
            text = text.replacingOccurrences(of: " \(p)", with: p)
        }
        // Capitalize the first letter.
        if let first = text.first, first.isLowercase {
            text.replaceSubrange(text.startIndex...text.startIndex, with: String(first).uppercased())
        }
        // Ensure terminal punctuation.
        if let last = text.last, !".!?".contains(last) {
            text.append(".")
        }
        return text
    }

    // MARK: - Loading

    private struct FunDefinitionsFile: Decodable {
        let definitions: [FunDefinition]
    }

    private struct FunDefinition: Decodable {
        let word: String
        let funDefinition: String
    }

    private static func loadBundledDefinitions() -> [FunDefinition] {
        guard let url = Bundle.main.url(forResource: "fun_definitions", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(FunDefinitionsFile.self, from: data)
        else { return [] }
        return file.definitions
    }
}
