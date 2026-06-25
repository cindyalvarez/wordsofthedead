import Foundation

/// Persists the roster of saved players and which player was last active, so subsequent
/// launches can offer "continue as <name>" or starting fresh under a new name.
///
/// `~/Library/Application Support/WordsOfTheDead/players.json`
///
/// Each player's actual progress (learning profile + daily goal history) lives under
/// `players/<id>/` and is read/written by `LearningStore` / `DailyGoalStore` once the
/// active player is selected.
enum PlayerStore {
    struct Roster: Codable {
        var players: [Player] = []
        var lastPlayerID: String?
        /// True once the one-time pre-player legacy progress has been claimed by the first
        /// player. Prevents any later player from inheriting that old progress.
        var legacyMigrated: Bool = false

        init(players: [Player] = [], lastPlayerID: String? = nil, legacyMigrated: Bool = false) {
            self.players = players
            self.lastPlayerID = lastPlayerID
            self.legacyMigrated = legacyMigrated
        }

        enum CodingKeys: String, CodingKey { case players, lastPlayerID, legacyMigrated }

        // Decode resiliently: a roster written by an earlier version may be missing newer
        // keys. Synthesized Codable would throw `keyNotFound` (collapsing the whole roster to
        // empty and making every new player look like the "first" one); `decodeIfPresent`
        // falls back to defaults instead.
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            players = try c.decodeIfPresent([Player].self, forKey: .players) ?? []
            lastPlayerID = try c.decodeIfPresent(String.self, forKey: .lastPlayerID)
            legacyMigrated = try c.decodeIfPresent(Bool.self, forKey: .legacyMigrated) ?? false
        }
    }

    static var fileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let dir = base.appendingPathComponent("WordsOfTheDead", isDirectory: true)
        return dir.appendingPathComponent("players.json")
    }

    static func load() -> Roster {
        let decoder = JSONDecoder()
        
        // Try loading with error recovery
        if let recovered: Roster = FileUtilities.loadWithRecovery(from: fileURL, decoder: decoder) {
            return recovered
        }
        
        // Fallback to empty roster
        FileUtilities.log("Roster load failed, using empty roster", category: "load")
        return Roster()
    }

    @discardableResult
    static func save(_ roster: Roster) -> Bool {
        guard let data = try? JSONEncoder().encode(roster) else {
            FileUtilities.log("Failed to encode roster", category: "save")
            return false
        }
        
        // Create backup before writing
        FileUtilities.createBackupIfNeeded(for: fileURL)
        
        // Write atomically
        return FileUtilities.writeAtomically(data, to: fileURL)
    }

    /// A filesystem-safe identifier derived from a display name. Names that reduce to the
    /// same slug (case/punctuation-insensitive) are treated as the same player.
    static func slug(for name: String) -> String {
        let lowered = name.lowercased()
        let mapped = lowered.map { ch -> Character in
            (ch.isLetter || ch.isNumber) ? ch : "-"
        }
        let collapsed = String(mapped)
            .split(separator: "-", omittingEmptySubsequences: true)
            .joined(separator: "-")
        return collapsed.isEmpty ? "player" : collapsed
    }
}
