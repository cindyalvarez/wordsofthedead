import Foundation

/// Persists QA corrections to the fun definitions in a user-writable location, so that
/// edits made in `--qa` review mode feed back into normal gameplay on the next launch.
///
/// The app bundle's `fun_definitions.json` is read-only, so corrections are stored
/// separately (keyed by lowercased word) and layered on top when definitions are loaded.
enum FunDefinitionOverrides {

    /// `~/Library/Application Support/WordsOfTheDead/fun_overrides.json`
    static var fileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let dir = base.appendingPathComponent("WordsOfTheDead", isDirectory: true)
        return dir.appendingPathComponent("fun_overrides.json")
    }

    static func load() -> [String: String] {
        guard let data = try? Data(contentsOf: fileURL),
              let map = try? JSONDecoder().decode([String: String].self, from: data)
        else { return [:] }
        return map
    }

    /// Merges the given corrections (word → corrected sentence) into the saved overrides.
    @discardableResult
    static func save(_ corrections: [String: String]) -> Bool {
        var map = load()
        for (word, sentence) in corrections {
            let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }
            map[word.lowercased()] = trimmed
        }
        let dir = fileURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        guard let data = try? JSONEncoder().encode(map) else { return false }
        return (try? data.write(to: fileURL)) != nil
    }
}
