#!/bin/bash
# Poll YouTrack for Team Aurora (01A) issues; snapshot to corpus and flag changes in TRIAGE.md
set -euo pipefail
source "$HOME/Desktop/Capstone/.env"
OUT="$HOME/Desktop/Capstone/corpus/youtrack"
mkdir -p "$OUT"
NEW="$OUT/issues.json"
OLD="$OUT/issues.prev.json"

curl -sf -H "Authorization: Bearer $YOUTRACK_TOKEN" \
  "$YOUTRACK_URL/api/issues?query=project:%2001A%20sort%20by:%20updated%20desc&fields=idReadable,summary,updated,customFields(name,value(name,login))&\$top=200" \
  -o "$NEW.tmp"
[ -s "$NEW.tmp" ] || { rm -f "$NEW.tmp"; exit 1; }
[ -f "$NEW" ] && cp "$NEW" "$OLD"
mv "$NEW.tmp" "$NEW"

python3 - <<'EOF'
import json, os, datetime
home = os.path.expanduser("~")
new = json.load(open(f"{home}/Desktop/Capstone/corpus/youtrack/issues.json"))
try: old = {i["idReadable"]: i for i in json.load(open(f"{home}/Desktop/Capstone/corpus/youtrack/issues.prev.json"))}
except Exception: old = None
def sig(i):
    d = {f["name"]: f.get("value") for f in i.get("customFields", [])}
    st = (d.get("State") or {}).get("name", "") if isinstance(d.get("State"), dict) else ""
    a = d.get("Assignee")
    asg = a.get("login","") if isinstance(a, dict) else ""
    return st, asg
lines = [f"# 01A Team Aurora — YouTrack board (synced {datetime.datetime.now():%Y-%m-%d %H:%M})\n"]
changes = []
for i in new:
    st, asg = sig(i)
    lines.append(f"- {i['idReadable']} [{st}] ({asg}) {i['summary']}")
    if old is not None:
        o = old.get(i["idReadable"])
        if o is None: changes.append(f"NEW ISSUE: {i['idReadable']} {i['summary']}")
        elif sig(o) != (st, asg) or o["summary"] != i["summary"]:
            changes.append(f"CHANGED: {i['idReadable']} now [{st}] ({asg}) {i['summary']}")
open(f"{home}/Desktop/Capstone/corpus/youtrack/BOARD.md","w").write("\n".join(lines)+"\n")
if changes:
    with open(f"{home}/Desktop/Capstone/inbox/TRIAGE.md","a") as f:
        f.write(f"\n## [NEW] YouTrack {datetime.datetime.now():%Y-%m-%d %H:%M}\n" + "\n".join(f"- {c}" for c in changes) + "\n")
    print(f"{len(changes)} change(s) flagged")
EOF
