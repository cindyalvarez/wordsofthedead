import Foundation

/// Persists the level → background-image assignment so that a given level always keeps the
/// same background, even as new images are added later. New images simply get assigned to
/// the next-higher levels that don't yet have one; existing assignments are never disturbed.
///
/// Stored as `{ "<level>": "<imageName>" }` in:
/// `~/Library/Application Support/WordsOfTheDead/background_assignments.json`
enum BackgroundAssignmentStore {
    static var fileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let dir = base.appendingPathComponent("WordsOfTheDead", isDirectory: true)
        return dir.appendingPathComponent("background_assignments.json")
    }

    static func load() -> [Int: String] {
        guard let data = try? Data(contentsOf: fileURL),
              let map = try? JSONDecoder().decode([String: String].self, from: data)
        else { return [:] }
        return Dictionary(uniqueKeysWithValues: map.compactMap { key, value in
            Int(key).map { ($0, value) }
        })
    }

    @discardableResult
    static func save(_ assignments: [Int: String]) -> Bool {
        let map = Dictionary(uniqueKeysWithValues: assignments.map { (String($0.key), $0.value) })
        guard let data = try? JSONEncoder().encode(map) else {
            FileUtilities.log("Failed to encode background assignments", category: "save")
            return false
        }
        
        // Create backup before writing
        FileUtilities.createBackupIfNeeded(for: fileURL)
        
        // Write atomically
        return FileUtilities.writeAtomically(data, to: fileURL)
    }
}
