import Foundation

/// Persists the spaced-repetition learning profile (word → progress) to a user-writable
/// file so mastery survives across launches. Namespaced per player via `playerID`.
///
/// `~/Library/Application Support/WordsOfTheDead/players/<playerID>/learning_profile.json`
enum LearningStore {
    /// Identifier of the player whose profile is being read/written. Set when a player is
    /// selected; defaults so the store is usable before any explicit selection.
    static var playerID: String = "default"

    static var fileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let dir = base
            .appendingPathComponent("WordsOfTheDead", isDirectory: true)
            .appendingPathComponent("players", isDirectory: true)
            .appendingPathComponent(playerID, isDirectory: true)
        return dir.appendingPathComponent("learning_profile.json")
    }

    static func load() -> [String: WordProgress] {
        let decoder = JSONDecoder()
        
        // Try loading with error recovery
        if let recovered: [String: WordProgress] = FileUtilities.loadWithRecovery(from: fileURL, decoder: decoder) {
            return recovered
        }
        
        // Fallback to empty profile
        FileUtilities.log("Learning profile load failed, using empty profile", category: "load")
        return [:]
    }

    @discardableResult
    static func save(_ profile: [String: WordProgress]) -> Bool {
        guard let data = try? JSONEncoder().encode(profile) else {
            FileUtilities.log("Failed to encode learning profile", category: "save")
            return false
        }
        
        // Create backup before writing
        FileUtilities.createBackupIfNeeded(for: fileURL)
        
        // Write atomically
        return FileUtilities.writeAtomically(data, to: fileURL)
    }

    /// Pre-player-system location of the global learning profile.
    private static var legacyURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return base
            .appendingPathComponent("WordsOfTheDead", isDirectory: true)
            .appendingPathComponent("learning_profile.json")
    }

    /// Where the legacy file is moved once it has been migrated, so it is preserved as a
    /// backup but can never be migrated into a player again.
    private static var consumedLegacyURL: URL {
        legacyURL.deletingLastPathComponent().appendingPathComponent("learning_profile.migrated.json")
    }

    /// One-time migration: if a legacy (pre-player) profile exists and the current player
    /// has none yet, copy it in so earlier progress isn't lost. The legacy file is then
    /// consumed so no later player can inherit it.
    static func migrateLegacyIfNeeded() {
        let fm = FileManager.default
        guard fm.fileExists(atPath: legacyURL.path) else { return }
        if !fm.fileExists(atPath: fileURL.path) {
            try? fm.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? fm.copyItem(at: legacyURL, to: fileURL)
        }
        consumeLegacy()
    }

    /// Renames the legacy top-level profile so a future "first" player (e.g. after a roster
    /// reset) can never re-inherit pre-player progress. Safe to call repeatedly.
    static func consumeLegacy() {
        let fm = FileManager.default
        guard fm.fileExists(atPath: legacyURL.path) else { return }
        try? fm.removeItem(at: consumedLegacyURL)
        try? fm.moveItem(at: legacyURL, to: consumedLegacyURL)
    }
}
