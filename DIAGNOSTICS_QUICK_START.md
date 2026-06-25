# Diagnostics Bundle — Quick Start

## For Users

**Export diagnostics for bug reports:**

```bash
# 1. Launch app in QA mode (enables logging)
open build/WordsOfTheDead.app --args --qa

# 2. Play game, reproduce issue

# 3. Trigger export (UI button when integrated)
# Bundle auto-opens in Finder

# 4. Attach zip file to bug report email
```

## For Developers

**Test diagnostics export:**

```bash
# Build app
cd ~/vibe/wordsofthedead
WOTD_NO_OPEN=1 ./WordsOfTheDead/build.sh

# Create bundle programmatically
open build/WordsOfTheDead.app --args --qa

# In app code:
if let bundleURL = FileUtilities.exportDiagnostics() {
    FileUtilities.revealDiagnosticsBundle(bundleURL)
}

# Verify bundle
unzip -l ~/Downloads/WordsOfTheDead-Diagnostics-*.zip
cat ~/Downloads/WordsOfTheDead-Diagnostics/MANIFEST.txt
```

**View logs:**

```bash
# Enable verbose logging
export WOTD_VERBOSE=1
open build/WordsOfTheDead.app

# Follow logs in real-time
tail -f ~/Library/Application\ Support/WordsOfTheDead/logs/wotd.log

# View all logs
cat ~/Library/Application\ Support/WordsOfTheDead/logs/wotd.log
```

## What's Included

✅ **In Bundle**:
- Event logs (timestamps, categories, messages)
- Player count and statistics
- System info (OS, locale, timezone)
- Manifest with privacy notice

❌ **NOT in Bundle**:
- Player names or IDs
- Learning profiles or word progress
- Daily goal history
- Personal settings

## Bundle Location

Automatically saved to:
```
~/Downloads/WordsOfTheDead-Diagnostics-YYYY-MM-DD.zip
(Fallback to ~/Desktop/ if needed)
```

## Files

- `FileUtilities.swift` — `exportDiagnostics()`, `revealDiagnosticsBundle()`
- `DiagnosticsExportView.swift` — SwiftUI modal for export UI
- `DIAGNOSTICS_BUNDLE_GUIDE.md` — Full documentation
- `DIAGNOSTICS_IMPLEMENTATION_COMPLETE.md` — Implementation details

## Next: Menu Integration

Add to menu bar (File > Export Diagnostics):

```swift
// In WordsOfTheDeadApp.swift or settings menu
Button("Export Diagnostics...") {
    FileUtilities.exportDiagnostics()
}
```

---

For details, see: `DIAGNOSTICS_BUNDLE_GUIDE.md`
