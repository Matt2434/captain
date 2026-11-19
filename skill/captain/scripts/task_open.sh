#!/bin/bash
# Reopen a closed issue/PR workspace from its hand-off file.
# Usage: task_open.sh <card> [emoji] [label]     e.g. task_open.sh 01A-229 🛠️ "Prompt + schema"
# Reads __PROJECT_DIR__/drafts/handoffs/<card>/STATE.md; opens "CAP <emoji> <card> <label>",
# a fresh low-effort Claude session (left) and an Aurora VM pane (right).
set -euo pipefail; export CMUX_QUIET=1
CARD=${1:?card id, e.g. 01A-229}; EMOJI=${2:-🛠️}; LABEL=${3:-}
D=__PROJECT_DIR__/drafts/handoffs/$CARD
[ -f "$D/STATE.md" ] || { echo "no $D/STATE.md"; ls __PROJECT_DIR__/drafts/handoffs/ 2>/dev/null; exit 1; }
NAME="CAP $EMOJI $CARD${LABEL:+ $LABEL}"
cmux new-workspace --name "$NAME" --cwd __PROJECT_DIR__ --focus false --command "claude --model claude-opus-5-5 --effort low" >/dev/null
sleep 3
read W S < <(cmux tree --json | python3 -c "
import json,sys
for w in json.load(sys.stdin)['windows'][0]['workspaces']:
  if w['title']==sys.argv[1]: print(w['ref'], w['panes'][0]['surfaces'][0]['ref'])" "$NAME")
R=$(cmux new-split right --workspace "$W" --surface "$S" --focus false | grep -o 'surface:[0-9]*' | head -1)
cmux send --surface "$R" "ssh -o ConnectTimeout=8 -o ServerAliveInterval=30 __SCHOOL_USER__@__VM_HOST__"; cmux send-key --surface "$R" Enter
for i in $(seq 15); do cmux read-screen --surface "$S" | grep -q 'auto mode\|Try "' && break; sleep 2; done
cmux send --surface "$S" --paste "Resume $CARD. Read ONLY drafts/handoffs/$CARD/STATE.md first, then the live PR and card it names (they win over STATE.md if they differ). Follow __PROJECT_DIR__/CLAUDE.md. Your VM pane is $R. Do not act yet: give Matt a 5-line status (state, what changed since STATE.md, waiting on, next step) and wait for his instruction. Update STATE.md after each decision. Finish tasks with the End-of-task report format."
sleep 1; cmux send-key --surface "$S" Enter
echo "opened $NAME ($W, left $S, VM $R)"
