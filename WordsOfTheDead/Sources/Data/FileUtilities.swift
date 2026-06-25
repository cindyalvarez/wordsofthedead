import Foundation
import AppKit

/// Shared utilities for resilient file I/O: atomic writes, backups, and error recovery.
enum FileUtilities {
    
    // MARK: - Logging
    
    private static var logsDir: URL? {
        guard let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let logsPath = base.appendingPathComponent("WordsOfTheDead", isDirectory: true)
            .appendingPathComponent("logs", isDirectory: true)
        try? FileManager.default.createDirectory(at: logsPath, withIntermediateDirectories: true)
        return logsPath
    }
    
    /// Write a log message if verbose logging is enabled (in QA mode or via WOTD_VERBOSE env var).
    static func log(_ message: String, category: String = "general") {
        let isQA = CommandLine.arguments.contains("--qa")
        let isVerbose = ProcessInfo.processInfo.environment["WOTD_VERBOSE"] != nil
        guard isQA || isVerbose else { return }
        
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logLine = "[\(timestamp)] [\(category)] \(message)"
        
        // Also print to stdout in QA mode
        if isQA {
            print(logLine)
        }
        
        // Append to log file
        guard let logsDir = logsDir else { return }
        let logFile = logsDir.appendingPathComponent("wotd.log")
        let data = (logLine + "\n").data(using: .utf8) ?? Data()
        if FileManager.default.fileExists(atPath: logFile.path) {
            if let handle = FileHandle(forWritingAtPath: logFile.path) {
                defer { try? handle.close() }
                handle.seekToEndOfFile()
                handle.write(data)
            }
        } else {
            try? data.write(to: logFile)
        }
    }
    
    // MARK: - Atomic Writes
    
    /// Write data atomically: write to a temp file, then rename to target.
    /// If the process crashes during write, the target file remains untouched.
    /// Returns true on success.
    static func writeAtomically(_ data: Data, to fileURL: URL) -> Bool {
        let dir = fileURL.deletingLastPathComponent()
        
        // Create directory if needed
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        } catch {
            log("Failed to create directory \(dir.path): \(error)", category: "save")
            return false
        }
        
        // Write to a temp file first
        let tempURL = fileURL.appendingPathExtension("tmp")
        do {
            try data.write(to: tempURL, options: [.atomic])
            
            // Atomic rename (POSIX move)
            try FileManager.default.removeItem(at: fileURL) // Remove target if exists
            try FileManager.default.moveItem(at: tempURL, to: fileURL)
            
            log("Saved \(fileURL.lastPathComponent) (\(data.count) bytes)", category: "save")
            return true
        } catch {
            log("Atomic write failed for \(fileURL.path): \(error)", category: "save")
            // Clean up temp file
            try? FileManager.default.removeItem(at: tempURL)
            return false
        }
    }
    
    // MARK: - Backups
    
    /// Create a timestamped backup of the file (if it exists).
    /// Backups are kept in a `backups/` subdirectory next to the original file.
    static func createBackupIfNeeded(for fileURL: URL) {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        
        let backupsDir = fileURL.deletingLastPathComponent()
            .appendingPathComponent("backups", isDirectory: true)
        
        do {
            try FileManager.default.createDirectory(at: backupsDir, withIntermediateDirectories: true)
        } catch {
            log("Failed to create backups directory: \(error)", category: "backup")
            return
        }
        
        // Timestamp backup with today's date and an incrementing counter
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateStr = dateFormatter.string(from: Date())
        
        var backupURL = backupsDir.appendingPathComponent(
            fileURL.lastPathComponent.replacingOccurrences(of: ".json", with: "_\(dateStr)_0.json")
        )
        
        // If today's backup already exists, increment counter
        var counter = 0
        while FileManager.default.fileExists(atPath: backupURL.path) {
            counter += 1
            backupURL = backupsDir.appendingPathComponent(
                fileURL.lastPathComponent.replacingOccurrences(of: ".json", with: "_\(dateStr)_\(counter).json")
            )
        }
        
        do {
            try FileManager.default.copyItem(at: fileURL, to: backupURL)
            log("Backup created: \(backupURL.lastPathComponent)", category: "backup")
        } catch {
            log("Failed to create backup: \(error)", category: "backup")
        }
    }
    
    /// Find the latest backup for a given file.
    static func latestBackup(for fileURL: URL) -> URL? {
        let backupsDir = fileURL.deletingLastPathComponent()
            .appendingPathComponent("backups", isDirectory: true)
        
        guard let backups = try? FileManager.default.contentsOfDirectory(
            at: backupsDir,
            includingPropertiesForKeys: [.contentModificationDateKey]
        ) else {
            return nil
        }
        
        // Filter to backups of this specific file and sort by modification date (newest first)
        let baseName = fileURL.lastPathComponent.replacingOccurrences(of: ".json", with: "")
        let matching = backups
            .filter { $0.lastPathComponent.hasPrefix(baseName) }
            .sorted {
                let date1 = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
                let date2 = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
                return date1 > date2
            }
        
        return matching.first
    }
    
    // MARK: - Error Recovery
    
    /// Attempt to load from file; if malformed, try the latest backup; if that fails, return nil.
    static func loadWithRecovery<T: Decodable>(from fileURL: URL, decoder: JSONDecoder = JSONDecoder()) -> T? {
        // Try main file first
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? decoder.decode(T.self, from: data) {
            return decoded
        }
        
        log("Decode failed for \(fileURL.lastPathComponent), attempting recovery...", category: "recovery")
        
        // Try latest backup
        if let backupURL = latestBackup(for: fileURL),
           let data = try? Data(contentsOf: backupURL),
           let decoded = try? decoder.decode(T.self, from: data) {
            log("Recovered from backup: \(backupURL.lastPathComponent)", category: "recovery")
            
            // Restore the backup to the main file
            do {
                try FileManager.default.removeItem(at: fileURL)
                try FileManager.default.copyItem(at: backupURL, to: fileURL)
                log("Main file restored from backup", category: "recovery")
            } catch {
                log("Failed to restore backup: \(error)", category: "recovery")
            }
            
            return decoded
        }
        
        log("Recovery failed: no valid backup found", category: "recovery")
        return nil
    }
    
    // MARK: - Diagnostics
    
    /// Export a diagnostics bundle (zip file containing logs, config, and stats).
    /// Returns the path to the created .zip file.
    static func exportDiagnostics() -> URL? {
        guard let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let wotdDir = appSupportDir.appendingPathComponent("WordsOfTheDead")
        let tempDiagDir = appSupportDir.appendingPathComponent("WordsOfTheDead-Diagnostics-Temp")
        
        // Clean up any previous temp directory
        do {
            try FileManager.default.removeItem(at: tempDiagDir)
        } catch {}
        
        do {
            try FileManager.default.createDirectory(at: tempDiagDir, withIntermediateDirectories: true)
            
            // Copy logs
            let logsSourceDir = wotdDir.appendingPathComponent("logs")
            let logsDest = tempDiagDir.appendingPathComponent("logs")
            if FileManager.default.fileExists(atPath: logsSourceDir.path) {
                try FileManager.default.copyItem(at: logsSourceDir, to: logsDest)
            }
            
            // Copy player roster (sanitize: don't include personal data like player IDs, just count)
            let rosterSource = wotdDir.appendingPathComponent("players.json")
            if FileManager.default.fileExists(atPath: rosterSource.path) {
                if let rosterData = try? Data(contentsOf: rosterSource),
                   let json = try? JSONSerialization.jsonObject(with: rosterData) as? [String: Any] {
                    let playerCount = (json["players"] as? [[String: Any]])?.count ?? 0
                    let summary = """
                    Player Roster Summary
                    ====================
                    Players: \(playerCount)
                    Last Updated: \(DateFormatter().string(from: Date()))
                    
                    (Full roster not included to protect privacy)
                    """
                    try summary.write(
                        to: tempDiagDir.appendingPathComponent("roster_summary.txt"),
                        atomically: true,
                        encoding: String.Encoding.utf8
                    )
                }
            }
            
            // Create a detailed manifest with system and app information
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .medium
            
            let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
            let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
            let locale = Locale.current.identifier
            let timezone = TimeZone.current.abbreviation() ?? "unknown"
            
            let manifest = """
            Words of the Dead — Diagnostics Bundle
            =====================================
            
            Generated: \(ISO8601DateFormatter().string(from: Date()))
            
            SYSTEM INFORMATION
            -------------------
            OS Version: \(osVersion)
            Locale: \(locale)
            Timezone: \(timezone)
            
            APPLICATION
            -----------
            App Version: \(appVersion)
            Build Number: \(buildNumber)
            Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")
            
            CONTENTS
            --------
            - logs/ : Game event logs (QA mode logging)
            - roster_summary.txt : Player count and metadata
            - MANIFEST.txt : This file
            
            PRIVACY NOTE
            ------------
            This bundle contains non-sensitive diagnostic information:
            - Application logs and error traces
            - Aggregated player statistics (no player names or personal data)
            - System environment information
            
            It does NOT contain:
            - Individual player learning profiles
            - Daily goal history
            - Personal player settings
            
            USE CASES
            ---------
            Share this bundle when reporting bugs, to help developers:
            - Understand your system environment
            - Review error logs and crash traces
            - See when issues occurred
            
            For support, email this bundle along with:
            1. Description of the problem
            2. Steps to reproduce
            3. Expected vs. actual behavior
            """
            
            try manifest.write(
                to: tempDiagDir.appendingPathComponent("MANIFEST.txt"),
                atomically: true,
                encoding: String.Encoding.utf8
            )
            
            // Create zip file in Downloads or Desktop
            let dateStr = dateFormatter.string(from: Date()).replacingOccurrences(of: "/", with: "-")
            let zipName = "WordsOfTheDead-Diagnostics-\(dateStr).zip"
            
            // Try Downloads first, fall back to Desktop, then Desktop
            var outputDir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
            if outputDir == nil {
                outputDir = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
            }
            
            guard let outputURL = outputDir?.appendingPathComponent(zipName) else {
                throw NSError(domain: "Export", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not determine output directory"])
            }
            
            // Use Foundation's Process to run zip command (more reliable than manual compression)
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
            process.arguments = ["-r", "-q", outputURL.path, "."]
            process.currentDirectoryURL = tempDiagDir
            
            let errorPipe = Pipe()
            process.standardError = errorPipe
            
            try process.run()
            process.waitUntilExit()
            
            guard process.terminationStatus == 0 else {
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let errorMsg = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                throw NSError(domain: "Zip", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMsg])
            }
            
            log("Diagnostics bundle created: \(outputURL.path)", category: "diagnostics")
            
            // Cleanup temp directory
            try? FileManager.default.removeItem(at: tempDiagDir)
            
            return outputURL
        } catch {
            log("Failed to export diagnostics: \(error)", category: "diagnostics")
            return nil
        }
    }
    
    /// Open the diagnostics bundle in Finder after export.
    static func revealDiagnosticsBundle(_ url: URL) {
        NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
    }
}
