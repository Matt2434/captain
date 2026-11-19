#!/bin/bash
# mdpane.sh <file.md> — open a Capstone markdown file with glow in a NEW RIGHT PANE in cmux.
# Rule (CLAUDE.md): whenever Matt asks to view/pull up an .md from __PROJECT_DIR__,
# use this instead of cat/Read display.
set -euo pipefail
FILE="${1:?usage: mdpane.sh <file.md>}"
FILE="$(cd "$(dirname "$FILE")" && pwd)/$(basename "$FILE")"
OUT=$(cmux new-split right)
SURFACE=$(echo "$OUT" | grep -oE 'surface:[0-9]+' | head -1)
[ -n "$SURFACE" ] || { echo "split failed: $OUT"; exit 1; }
sleep 1
cmux send-panel --panel "$SURFACE" -- "glow -p \"$FILE\"\n"
echo "opened $FILE in $SURFACE"
