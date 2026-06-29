#!/usr/bin/env python3
"""Parse vocablist.txt into a clean structured vocab.json, with 8th-grade words merged in.

The source file is a reflowed two-column PDF dump: each vocabulary entry begins a
line in the form

    word (pos.) short definition (example sentence...

but the example-sentence text wraps and interleaves out of order across following
lines. Per the app spec we discard the example sentences entirely and keep only the
word, part of speech, and the short definition (the text after `(pos.)` and before the
opening parenthesis of the example sentence).

Some entries have numbered senses, e.g.

    abide 1. (v.) to put up with (...) 2. (v.) to remain (...)

We keep the first sense's part of speech / definition as the primary definition and
record any additional senses too.

If vocab_8th_grade.json exists, we also merge in the 8th-grade vocabulary with
minLevel set to 1-50, and set minLevel to 51+ for the original words.
"""

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "vocablist.txt"
OUT = ROOT / "data" / "vocab.json"
VOCAB_8TH_GRADE = ROOT / "data" / "vocab_8th_grade.json"

POS = r"(?:n|v|adj|adv)"

# An entry line starts at column 0 with a headword, then either `(pos.)` directly
# or a numbered sense `1. (pos.)`.
ENTRY_RE = re.compile(rf"^([A-Za-z][A-Za-z''\-]*)\s+(?:\d+\.\s+)?\({POS}\.\)")

# Matches each sense marker within the line so we can split multi-sense entries.
SENSE_RE = re.compile(rf"(?:(\d+)\.\s+)?\(({POS})\.\)")


def clean_def(text: str) -> str:
    """Take definition text up to the first '(' (start of example) and tidy it."""
    cut = text.split("(", 1)[0]
    cut = cut.strip()
    # Drop a trailing numbered-sense marker that belongs to the next sense, e.g.
    # "to put up with  2." -> "to put up with"
    cut = re.sub(r"\s*\d+\.\s*$", "", cut)
    return cut.strip(" \t,;")


def parse_entry(line: str):
    m = ENTRY_RE.match(line)
    if not m:
        return None
    word = m.group(1)

    senses = []
    matches = list(SENSE_RE.finditer(line))
    for i, sm in enumerate(matches):
        pos = sm.group(2)
        start = sm.end()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(line)
        definition = clean_def(line[start:end])
        if definition:
            senses.append({"pos": pos, "definition": definition})

    if not senses:
        return None

    return {
        "word": word,
        "pos": senses[0]["pos"],
        "shortDefinition": senses[0]["definition"],
        "senses": senses,
    }


def main():
    if not SRC.exists():
        sys.exit(f"Source not found: {SRC}")

    entries = []
    seen = set()
    
    # First, load 8th-grade vocabulary if it exists (these get priority)
    if VOCAB_8TH_GRADE.exists():
        try:
            vocab_8th = json.loads(VOCAB_8TH_GRADE.read_text(encoding="utf-8"))
            for entry in vocab_8th:
                key = entry["word"].lower()
                if key not in seen:
                    # Keep the minLevel from the 8th-grade vocab (should be 1)
                    if "minLevel" not in entry:
                        entry["minLevel"] = 1
                    entries.append(entry)
                    seen.add(key)
        except Exception as e:
            print(f"Warning: Could not load 8th-grade vocabulary: {e}", file=sys.stderr)

    # Then, parse original vocablist.txt (only add if not already in 8th-grade)
    for raw in SRC.read_text(encoding="utf-8", errors="replace").splitlines():
        line = raw.rstrip()
        if not line:
            continue
        entry = parse_entry(line)
        if not entry:
            continue
        key = entry["word"].lower()
        if key in seen:
            continue
        seen.add(key)
        # Original words start at level 51+
        entry["minLevel"] = 51
        entries.append(entry)

    entries.sort(key=lambda e: e["word"].lower())
    OUT.write_text(json.dumps(entries, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Parsed {len(entries)} unique entries -> {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()

