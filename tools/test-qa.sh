#!/bin/bash
# Quick-start test runner for Words of the Dead bug prevention features

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
APP="$ROOT/build/WordsOfTheDead.app"
LOGS="$HOME/Library/Application Support/WordsOfTheDead/logs"

echo "🧪 Words of the Dead — QA Test Runner"
echo ""

# Build
echo "📦 Building app..."
WOTD_NO_OPEN=1 "$ROOT/WordsOfTheDead/build.sh" > /dev/null
echo "   ✅ Build successful"

# Launch in QA mode
echo ""
echo "🎮 Launching app in QA mode..."
echo "   Logs will appear below (Ctrl+C to stop):"
echo ""

# Create a named fifo for log following
LOGFILE="$LOGS/wotd.log"
mkdir -p "$LOGS"

# Clear old log
> "$LOGFILE" 2>/dev/null || true

# Launch app and tail logs in parallel
open "$APP" --args --qa &
APP_PID=$!

# Give app a moment to start
sleep 2

# Tail logs with timeout (follow mode)
timeout 30 tail -f "$LOGFILE" 2>/dev/null || true

echo ""
echo "✅ QA mode launched. Check the app window and logs above."
echo ""
echo "Test checklist:"
echo "  [ ] Create a new player"
echo "  [ ] Play a few levels"
echo "  [ ] Check logs for 'save' and 'load' entries"
echo "  [ ] Close app"
echo "  [ ] Relaunch and verify player data persists"
echo ""
echo "Log file: $LOGFILE"
echo "Backup dir: $HOME/Library/Application Support/WordsOfTheDead/players/*/backups/"
echo ""
