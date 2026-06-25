#!/bin/bash
# Verifies all background images in reference-images/ are included in the built app.
# If new images are found, displays them and exits with status 1.
# Called automatically by build.sh.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REFERENCE="$ROOT/reference-images/backgrounds"
BUILT="$ROOT/build/WordsOfTheDead.app/Contents/Resources/backgrounds"

if [ ! -d "$REFERENCE" ]; then
    echo "⚠️  Warning: reference images directory not found: $REFERENCE"
    exit 0
fi

if [ ! -d "$BUILT" ]; then
    echo "⚠️  Warning: built app not found yet (this is normal on first build)"
    exit 0
fi

# Find images in reference but not in built
MISSING=$(comm -23 <(ls -1 "$REFERENCE"/*.jpg 2>/dev/null | xargs -n1 basename | sort) \
                    <(ls -1 "$BUILT"/*.jpg 2>/dev/null | xargs -n1 basename | sort) || true)

if [ -n "$MISSING" ]; then
    echo ""
    echo "🎨 NEW BACKGROUND IMAGES DETECTED:"
    echo "$MISSING" | sed 's/^/   • /'
    echo ""
    echo "These will be assigned to new levels when you play."
    echo "Run ./WordsOfTheDead/build.sh to include them."
    exit 1
fi

exit 0
