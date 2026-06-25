import Foundation

/// Validation utilities for player names and other user input.
enum InputValidation {
    
    /// Maximum length for player names (filesystem and display constraints).
    static let maxPlayerNameLength = 64
    
    /// Minimum length for player names.
    static let minPlayerNameLength = 1
    
    /// Validate and sanitize a player name.
    /// Returns a cleaned name if valid, nil if invalid.
    static func sanitizePlayerName(_ name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        
        // Check length
        guard trimmed.count >= minPlayerNameLength && trimmed.count <= maxPlayerNameLength else {
            FileUtilities.log(
                "Player name out of range: \(trimmed.count) chars (min \(minPlayerNameLength), max \(maxPlayerNameLength))",
                category: "validation"
            )
            return nil
        }
        
        // Remove leading/trailing whitespace already handled above
        // Allow letters, numbers, spaces, common punctuation
        let allowed = CharacterSet.letters
            .union(.decimalDigits)
            .union(CharacterSet(charactersIn: " '-"))
        
        let filtered = trimmed.unicodeScalars.filter { allowed.contains($0) }.map(String.init).joined()
        
        guard !filtered.isEmpty else {
            FileUtilities.log(
                "Player name contains only invalid characters: '\(trimmed)'",
                category: "validation"
            )
            return nil
        }
        
        if filtered != trimmed {
            FileUtilities.log(
                "Player name sanitized: '\(trimmed)' → '\(filtered)'",
                category: "validation"
            )
        }
        
        return filtered
    }
    
    /// Check if a player name is valid without modification.
    static func isValidPlayerName(_ name: String) -> Bool {
        sanitizePlayerName(name) == name
    }
}
