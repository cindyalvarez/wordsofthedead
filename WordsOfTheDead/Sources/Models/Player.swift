import Foundation

/// A saved player. Each player has their own learning profile and daily-goal history
/// (stored under `players/<id>/`), plus lightweight best-progress metadata shown on the
/// player-select screen.
struct Player: Codable, Identifiable, Equatable {
    /// Filesystem-safe slug derived from the name; also the identity of the player.
    let id: String
    var name: String
    var createdAt: Date
    var lastPlayedAt: Date
    var bestLevel: Int
    var bestScore: Int
    var gamesPlayed: Int
    var hasWatchedCutscene: Bool

    init(id: String, name: String, createdAt: Date = Date(), lastPlayedAt: Date = Date(),
         bestLevel: Int = 1, bestScore: Int = 0, gamesPlayed: Int = 0, hasWatchedCutscene: Bool = false) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.lastPlayedAt = lastPlayedAt
        self.bestLevel = bestLevel
        self.bestScore = bestScore
        self.gamesPlayed = gamesPlayed
        self.hasWatchedCutscene = hasWatchedCutscene
    }

    enum CodingKeys: String, CodingKey {
        case id, name, createdAt, lastPlayedAt, bestLevel, bestScore, gamesPlayed, hasWatchedCutscene
    }

    // Decode resiliently so a player record written by an earlier version (missing a newer
    // optional-with-default field) still loads instead of failing the whole roster decode.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        lastPlayedAt = try c.decodeIfPresent(Date.self, forKey: .lastPlayedAt) ?? Date()
        bestLevel = try c.decodeIfPresent(Int.self, forKey: .bestLevel) ?? 1
        bestScore = try c.decodeIfPresent(Int.self, forKey: .bestScore) ?? 0
        gamesPlayed = try c.decodeIfPresent(Int.self, forKey: .gamesPlayed) ?? 0
        hasWatchedCutscene = try c.decodeIfPresent(Bool.self, forKey: .hasWatchedCutscene) ?? false
    }
}
