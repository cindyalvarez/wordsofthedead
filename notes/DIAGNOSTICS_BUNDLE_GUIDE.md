# Diagnostics Bundle Feature Guide

## Overview

The Diagnostics Bundle system allows users to easily export support bundles containing logs, system information, and player statistics for troubleshooting. This enables better bug reporting and faster issue resolution.

## User Features

### How to Access

1. **From the Game**:
   - Launching the game with `--qa` flag enables verbose logging
   - The DiagnosticsExportView is accessible via the sheet mechanism
   - Can be triggered programmatically from menu options or buttons

2. **Current Implementation**:
   - DiagnosticsExportView available in GameView as a sheet
   - Can be extended to add a button in Settings/Help menu
   - Keyboard shortcut: Integrate into menu bar (File > Export Diagnostics)

### What's Included

✅ **Included (Non-Sensitive)**:
- Event logs from QA mode logging (`logs/wotd.log`)
- Player count summary (roster_summary.txt)
- System information (OS, locale, timezone)
- Application metadata (version, build number, bundle ID)
- Manifest with privacy information

❌ **NOT Included (Privacy Protection)**:
- Individual player names or IDs
- Learning profiles or word progress
- Daily goal history
- Personal player settings
- Raw game save files

### Export Process

1. User clicks "Create Bundle" button
2. App collects logs and creates temporary staging directory
3. Runs macOS `/usr/bin/zip` to create compressed bundle
4. Saves to `~/Downloads/WordsOfTheDead-Diagnostics-DATE.zip`
5. Opens bundle location in Finder
6. User can then email or upload bundle to support

## Developer Features

### Creating a Diagnostics Export Programmatically

```swift
// Export and get the bundle URL
if let bundleURL = FileUtilities.exportDiagnostics() {
    // Bundle created successfully
    print("Diagnostics saved to: \(bundleURL.path)")
    
    // Reveal in Finder
    FileUtilities.revealDiagnosticsBundle(bundleURL)
}
```

### Logging to Diagnostics Bundle

Enable verbose logging with:

```bash
export WOTD_VERBOSE=1
open build/WordsOfTheDead.app
```

Or run in QA mode:

```bash
open build/WordsOfTheDead.app --args --qa
```

Logs are automatically written to:
```
~/Library/Application Support/WordsOfTheDead/logs/wotd.log
```

Log format:
```
[2025-06-23T09:15:30Z] [save] Saved players.json (456 bytes)
[2025-06-23T09:15:31Z] [load] Learning profile load failed, using empty profile
[2025-06-23T09:15:32Z] [recovery] Recovered from backup: learning_profile_2025-06-23_0.json
[2025-06-23T09:15:33Z] [backup] Backup created: learning_profile_2025-06-23_0.json
```

### Log Categories

- **save**: File save operations
- **load**: File load operations
- **backup**: Backup creation
- **recovery**: Data recovery from corrupted files
- **validation**: Input validation results
- **diagnostics**: Diagnostics export operations
- **general**: Uncategorized messages

### Using the DiagnosticsExportView

```swift
import SwiftUI

struct SettingsView: View {
    @State private var showDiagnosticsExport = false
    
    var body: some View {
        VStack {
            Button("Export Diagnostics for Support") {
                showDiagnosticsExport = true
            }
        }
        .sheet(isPresented: $showDiagnosticsExport) {
            DiagnosticsExportView()
        }
    }
}
```

## Bundle Structure

After export, the zip file contains:

```
WordsOfTheDead-Diagnostics-06-23-2025.zip
├── logs/
│   └── wotd.log                    # Event log (if QA mode enabled)
├── roster_summary.txt              # Player count and metadata
└── MANIFEST.txt                    # System info and privacy notice
```

### Example MANIFEST.txt

```
Words of the Dead — Diagnostics Bundle
=====================================

Generated: 2025-06-23T09:15:30Z

SYSTEM INFORMATION
-------------------
OS Version: Version 14.5 (Build 23F79)
Locale: en_US
Timezone: PDT

APPLICATION
-----------
App Version: 1.0
Build Number: 42
Bundle ID: com.example.WordsOfTheDead

CONTENTS
--------
- logs/ : Game event logs (QA mode logging)
- roster_summary.txt : Player count and metadata
- MANIFEST.txt : This file

PRIVACY NOTE
...
```

## Integration Points

### Current Implementation

1. **FileUtilities.swift**:
   - `exportDiagnostics()` — Creates and zips bundle
   - `revealDiagnosticsBundle()` — Opens in Finder

2. **DiagnosticsExportView.swift**:
   - SwiftUI modal for export workflow
   - Shows what's included/excluded
   - Displays progress and success/error states

3. **GameView.swift**:
   - Sheet mechanism for showing export view

### Future Enhancements

1. **Menu Bar Integration**:
   - Add "Export Diagnostics" to app menu
   - Create keyboard shortcut (Cmd+Shift+D)
   - Add "About" window with link to export

2. **Settings Screen**:
   - Add toggle for automatic diagnostics on crash
   - Allow customizing what gets included
   - Show log file size and age

3. **Cloud Integration** (future):
   - One-click upload to support server
   - Generate anonymous ticket ID
   - Automatic diagnostics collection on errors

4. **Advanced Options**:
   - Include anonymized learning profiles
   - Include performance metrics
   - Custom date range filtering

## Testing

### Manual Test: Create & Share Bundle

```bash
# 1. Launch in QA mode
open build/WordsOfTheDead.app --args --qa

# 2. Play a game, create players, interact with app
# (This generates logs)

# 3. Trigger diagnostics export from UI
# (Or programmatically: FileUtilities.exportDiagnostics())

# 4. Verify bundle created
ls -lh ~/Downloads/WordsOfTheDead-Diagnostics*.zip

# 5. Unzip and inspect contents
unzip -l ~/Downloads/WordsOfTheDead-Diagnostics*.zip

# 6. Verify manifest and logs
cat ~/Downloads/WordsOfTheDead-Diagnostics/MANIFEST.txt
head -20 ~/Downloads/WordsOfTheDead-Diagnostics/logs/wotd.log
```

### Automated Test: Export Without UI

```swift
// Quick export test (no UI needed)
if let bundleURL = FileUtilities.exportDiagnostics() {
    print("✅ Bundle created: \(bundleURL.lastPathComponent)")
    
    // Verify it's a valid zip
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
    process.arguments = ["-t", bundleURL.path]
    try? process.run()
    process.waitUntilExit()
    
    if process.terminationStatus == 0 {
        print("✅ Zip integrity verified")
    }
} else {
    print("❌ Export failed")
}
```

## Support Workflow

### For End Users Reporting Bugs

1. Launch game in QA mode: `open build/WordsOfTheDead.app --args --qa`
2. Reproduce the issue (app is logging everything)
3. Click "Export Diagnostics for Support"
4. Zip file opens in Finder
5. Attach zip to bug report email with:
   - Description of problem
   - Steps to reproduce
   - Expected vs. actual behavior
   - Bundle file

### For Developers Debugging Issues

1. Receive diagnostics bundle from user
2. Extract: `unzip WordsOfTheDead-Diagnostics-*.zip`
3. Review MANIFEST.txt for system info
4. Check logs/ directory for error traces
5. Cross-reference with known issues
6. Provide targeted fix based on system configuration

## Privacy & Security

### What's Captured
- **Timestamps**: When events occurred (helps identify patterns)
- **Categories**: What type of event (save, load, error)
- **Messages**: Error descriptions (no personal data)
- **System**: OS version, locale, timezone (not MAC address, disk info)

### What's NOT Captured
- Player names or IDs (roster_summary only shows count)
- Word lists or definitions (learning profile never exported)
- Keyboard input or user activity logs
- Filenames or directory structure (only app support data)
- Network traffic or URLs

### User Control
- Verbose logging disabled by default (opt-in via `--qa` flag)
- Bundle creation is explicit (no automatic sending)
- Users see exactly what's included before export
- Manifest clearly states privacy protections

## Technical Details

### File Locations

**Logs** (created only in QA mode):
```
~/Library/Application Support/WordsOfTheDead/logs/wotd.log
```

**Temporary staging** (cleaned up after zip):
```
~/Library/Application Support/WordsOfTheDead-Diagnostics-Temp/
```

**Output** (user-visible):
```
~/Downloads/WordsOfTheDead-Diagnostics-YYYY-MM-DD.zip
(Falls back to ~/Desktop/ if Downloads unavailable)
```

### Implementation Notes

- Uses macOS `/usr/bin/zip` command (standard on all Macs)
- Runs zip process asynchronously to avoid UI blocking
- Automatically cleans up temporary files after compression
- Handles missing logs gracefully (empty logs/ directory if none)
- Creates date-formatted filenames (sortable by date)

## Troubleshooting

### Bundle not created?

Check console log:
```bash
tail -20 ~/Library/Application\ Support/WordsOfTheDead/logs/wotd.log
```

Error message usually indicates:
- "Could not determine output directory" → No Downloads/Desktop folders
- "Zip process failed" → `/usr/bin/zip` missing (very rare on macOS)
- "Decode failed" → Corrupted app support files

### Bundle too large?

Log files grow over time. To trim:
```bash
# Rotate log file (app will create new one)
mv ~/Library/Application\ Support/WordsOfTheDead/logs/wotd.log \
   ~/Library/Application\ Support/WordsOfTheDead/logs/wotd.log.old

# Or delete directly (next export will have no logs)
rm ~/Library/Application\ Support/WordsOfTheDead/logs/wotd.log
```

### Want to disable logging?

Remove `--qa` flag when launching. Logging is opt-in via:
- Command-line flag: `--qa`
- Environment variable: `export WOTD_VERBOSE=1`

## Future Considerations

1. **Metrics Collection**: Add anonymized gameplay metrics
2. **Crash Reporting**: Auto-collect diagnostics on crashes
3. **Web Dashboard**: User portal to upload and track bundles
4. **Machine Learning**: Analyze patterns across bundles to identify common issues
5. **Cloud Sync**: Encrypt and backup diagnostics to user's iCloud
