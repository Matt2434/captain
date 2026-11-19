#!/bin/bash
# Reopen a deck review from its STATE.md. Usage: deck_open.sh <slug>   (e.g. status-2026-11-09)
set -euo pipefail; export CMUX_QUIET=1
SLUG=${1:?slug}; D=__PROJECT_DIR__/drafts/reviews/decks/$SLUG
[ -f "$D/STATE.md" ] || { echo "no $D/STATE.md"; ls __PROJECT_DIR__/drafts/reviews/decks/; exit 1; }
KIND=$(echo "$SLUG" | cut -d- -f1); KIND="$(tr a-z A-Z <<<"${KIND:0:1}")${KIND:1}"
MD=$(echo "$SLUG" | awk -F- '{print $3"-"$4}')
EMOJI="📽️"; [ "$KIND" = "Status" ] && EMOJI="📈"; [ "$KIND" = "Partner" ] && EMOJI="📉"
SW=$(grep -o -i -m1 'sprint[^0-9]\{0,3\}[0-9]\{1,2\}[^0-9]\{1,8\}[0-9]\{1,2\}' "$D/STATE.md" | grep -o '[0-9]\{1,2\}' | head -2 | tr '\n' ' ')
set -- $SW; TAG=${2:+S${1}W${2}}; TAG=${TAG:-S?W?}
NAME="CAP $EMOJI $KIND Deck $MD · $TAG"
cmux new-workspace --name "$NAME" --cwd __PROJECT_DIR__ --focus false --command "claude --model claude-opus-5-5 --effort low" >/dev/null
sleep 3
read W S < <(cmux tree --json | python3 -c "
import json,sys
for w in json.load(sys.stdin)['windows'][0]['workspaces']:
  if w['title']==sys.argv[1]: print(w['ref'], w['panes'][0]['surfaces'][0]['ref'])" "$NAME")
R=$(cmux new-split right --workspace "$W" --surface "$S" --focus false | grep -o 'surface:[0-9]*' | head -1)
cmux send --surface "$R" "ssh -o ServerAliveInterval=30 __SCHOOL_USER__@__VM_HOST__"; cmux send-key --surface "$R" Enter
for i in $(seq 15); do cmux read-screen --surface "$S" | grep -q 'auto mode\|Try "' && break; sleep 2; done
cmux send --surface "$S" --paste "Deck review resume ($SLUG). Read ONLY drafts/reviews/decks/$SLUG/STATE.md first; open other files (artifact HTML source, .pptx, rubric) only when a task needs them. Follow the 'Deck reviews' section of ~/.claude/skills/captain/SKILL.md: changes go in the existing artifact: edit the HTML in the deck folder and publish with url set to the artifact URL in STATE.md (read it first), never a new artifact, no posting or .pptx edits without Matt's OK, update STATE.md after each decision. Then give Matt a 5-line status: pending changes and open questions."
sleep 1; cmux send-key --surface "$S" Enter
echo "opened $NAME"
