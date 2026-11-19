#!/bin/zsh
# Live Astra review viewer: astra_view.sh <worktree>
WT=$1; LOG=$WT/.astra-live.log; touch $LOG
grep -qx '.astra-live.log' $(git -C $WT rev-parse --git-common-dir)/info/exclude 2>/dev/null || echo '.astra-live.log' >> $(git -C $WT rev-parse --git-common-dir)/info/exclude
while :; do
  clear; b=$(git -C $WT branch --show-current)
  f=$(ls $WT/docs/evaluation/$b/astra-review-*.md 2>/dev/null | sort -V | tail -1)
  print -P "%B%F{cyan}ASTRA (gpt-6-astra, low) · $b%f%b   $(date +%H:%M:%S)"
  if [[ -n $f ]]; then print -P "%BLatest saved: ${f:t}%b"; grep -E "MET|N/A|NOT APPLICABLE" $f | cut -c1-$((COLUMNS-2)) | head -12; print -P "%B→ $(grep -v '^\s*$' $f | tail -1)%b"; else echo "No saved review yet"; fi
  print -P "\n%B%F{yellow}Live output (.astra-live.log)%f%b"
  tail -n $((LINES-22)) $LOG | cut -c1-$((COLUMNS-2))
  sleep 5
done
