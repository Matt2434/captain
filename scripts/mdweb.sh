#!/bin/bash
# mdweb.sh <file.md> — open a markdown file in the local click-to-edit web view
# (scripts/mdweb/server.mjs + index.html) in a NEW RIGHT browser pane in cmux.
# Edits save back to the file (previous version kept as <file>.md.bak). Serves on 127.0.0.1 only.
set -euo pipefail
FILE="${1:?usage: mdweb.sh <file.md>}"
FILE="$(cd "$(dirname "$FILE")" && pwd)/$(basename "$FILE")"
DIR="$(cd "$(dirname "$0")" && pwd)/mdweb"
LOG="$HOME/Library/Logs/capstone-mdweb"; mkdir -p "$LOG"
PORT=8642
while lsof -iTCP:$PORT -sTCP:LISTEN >/dev/null 2>&1; do PORT=$((PORT+1)); done
nohup node "$DIR/server.mjs" "$FILE" "$PORT" > "$LOG/$PORT.log" 2>&1 &
for _ in 1 2 3 4 5 6 7 8 9 10; do curl -s "http://127.0.0.1:$PORT/api/file" >/dev/null && break; sleep 0.3; done
cmux new-pane --type browser --direction right --url "http://localhost:$PORT" --focus true
echo "opened $FILE at http://localhost:$PORT (stop: pkill -f \"server.mjs .*$PORT\")"
