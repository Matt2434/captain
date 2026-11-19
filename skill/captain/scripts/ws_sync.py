#!/usr/bin/env python3
"""Workspace sync loop (Matt, 12 Nov). Run in the Captain right-hand pane: python3 ~/.claude/skills/captain/ws_sync.py
Every 2 min, for every "CAP … 01A-N" workspace:
 1. PR badge: point it at the card's current PR from GitHub (open PR naming the card, else newest); move it when
    the card gets a new PR/branch; refresh stale state (e.g. "open" on a merged PR).
 2. Auto-close: when the card's PR is MERGED and the card has no other open PR, ask the session (once, only when
    idle) to write drafts/handoffs/<card>/STATE.md, then close the workspace once that file is updated and the
    session is idle again. Gives up (logs, leaves open) after 45 min.
Hold list: ~/.config/capstone-autoclose-hold.txt (one card per line) is never auto-closed.
3. Comment watcher: new GitHub comments/reviews by the reviewers in WATCH on the card's OPEN PR are pasted into that
   workspace's session (when idle) with an instruction to address them. First sight of a PR marks existing comments seen.
   Seen ids: ~/.config/capstone-comment-seen.json.
Flags: --once (one pass), --dry (print, change nothing).
"""
import json, os, re, subprocess, sys, time

R = "__GH_REPO__"
REPO_DIR = os.path.expanduser("__PROJECT_DIR__/__REPO_CHECKOUT__")
HANDOFFS = os.path.expanduser("__PROJECT_DIR__/drafts/handoffs")
HOLD = os.path.expanduser("~/.config/capstone-autoclose-hold.txt")
STATE = os.path.expanduser("~/.config/capstone-autoclose-state.json")
SEEN = os.path.expanduser("~/.config/capstone-comment-seen.json")
WATCH = {"teammate-gh-login": "FirstName"}  # GitHub login -> Teams first name
CARD_OF = {"138": "01A-229", "139": "01A-230"}  # PRs whose title/branch lack the card
DRY = "--dry" in sys.argv
ONCE = "--once" in sys.argv or DRY
ENV = dict(os.environ, CMUX_QUIET="1")


def log(msg):
    print(time.strftime("%H:%M:%S"), msg, flush=True)


def cmux(*a, cwd=None):
    return subprocess.run(["cmux", *a], capture_output=True, text=True, env=ENV, cwd=cwd).stdout


def gh_pulls():
    tok = subprocess.run(["gh", "auth", "token", "-u", "__GH_USER__"], capture_output=True, text=True).stdout.strip()
    o = subprocess.run(["gh", "pr", "list", "-R", R, "--state", "all", "--limit", "200",
                        "--json", "number,title,headRefName,state,author"], capture_output=True, text=True,
                       env=dict(os.environ, GH_TOKEN=tok))
    return json.loads(o.stdout) if o.returncode == 0 else None


def load(p, default):
    try:
        return json.load(open(p))
    except Exception:
        return default


def gh_api(path):
    tok = subprocess.run(["gh", "auth", "token", "-u", "__GH_USER__"], capture_output=True, text=True).stdout.strip()
    o = subprocess.run(["gh", "api", "--paginate", path], capture_output=True, text=True,
                       env=dict(os.environ, GH_TOKEN=tok))
    try:
        return json.loads(o.stdout.replace("][", ","))
    except Exception:
        return []


def new_comments(n, seen):
    out = []
    for kind, path in (("comment", f"repos/{R}/issues/{n}/comments"), ("inline", f"repos/{R}/pulls/{n}/comments"),
                       ("review", f"repos/{R}/pulls/{n}/reviews")):
        for c in gh_api(path):
            if (c.get("user") or {}).get("login") not in WATCH or not ((c.get("body") or "").strip() or (kind == "review" and c.get("state") == "APPROVED")):
                continue
            key = f"{kind}:{c['id']}"
            if key in seen:
                continue
            loc = f" ({c.get('path')}:{c.get('line') or c.get('original_line')})" if kind == "inline" else ""
            st = f" {c.get('state')}" if kind == "review" and c.get("state") else ""
            out.append((key, f"[{kind}{st}{loc} by {c['user']['login']}] {c.get('html_url')}\n{(c.get('body') or '(approved, no text)').strip()}"))
    return out


def watch_comments(pulls):
    """Every open __GH_USER__ PR: new comments/reviews by a watched reviewer go to the card's CAP workspace (newest match),
    or to inbox/TRIAGE.md when no workspace is open for that card."""
    seen = load(SEEN, {})
    wss = json.loads(cmux("tree", "--json"))["windows"][0]["workspaces"]
    for pr in pulls:
        if pr["state"] != "OPEN" or (pr.get("author") or {}).get("login") != "__GH_USER__":
            continue
        n = str(pr["number"])
        m = re.search(r"01A-\d+", pr["title"] + " " + pr["headRefName"] + " " + CARD_OF.get(n, ""))
        card = m.group(0) if m else f"PR #{n}"
        new = new_comments(pr["number"], set(seen.get(n, [])))
        if n not in seen:
            seen[n] = [k for k, _ in new]
            log(f"comments: watching PR #{n} {card} ({len(new)} existing marked seen)")
            continue
        if not new:
            continue
        ws = [w for w in wss if m and re.search(rf"^CAP\b.*\b{card}\b", w["title"]) and "AI graders" not in w["title"]]
        body = "\n\n".join(t for _, t in new)
        if ws:
            w = ws[-1]
            surf = next((p["surfaces"][0]["ref"] for p in w.get("panes", []) if p.get("surfaces")), None)
            if not surf or "claude_code=Idle" not in cmux("sidebar-state", "--workspace", w["ref"]):
                continue  # busy: retry next pass
            who = sorted({re.search(r" by (\S+)\]", t).group(1) for _, t in new})
            names = " and ".join(WATCH[x] for x in who)
            log(f"comments: {len(new)} new from {names} on PR #{n} -> {w['title']}")
            if not DRY:
                cmux("send", "--surface", surf, "--paste",
                     f"Captain comment watcher: new review feedback from {names} on PR #{n} ({card}). Read it, fix each point, "
                     f"run tests locally and on the VM, push, reply on the PR with bullets (change, commit, verify command), "
                     f"and re-request {', '.join(who)} per CLAUDE.md when all points are done. THEN, standing approval (Matt, 14 Nov), "
                     f"post ONE Teams sentence automatically, no header/bullets: for each reviewer run "
                     f"MENTION=<first name> MSG=<file> S=<screenshot dir> SEND=1 node __PROJECT_DIR__/scripts/pw/teams-send.mjs "
                     f"with text like '@{names} I've updated PR #{n} ({card}) based on your review and re-requested your review on GitHub, so it's ready for you.' "
                     f"If any point is deferred or disputed, do NOT post to Teams or re-request; ask Matt. "
                     f"APPROVAL (Matt, 14 Nov): if the feedback is an APPROVED review with nothing left to fix, do not change code or re-request: "
                     f"tick every met exit criterion on the card and PR body (never the merge box, never the verifier box until the verifier's "
                     f"approval is recorded), then tell Matt it is ready for a human to merge. Merge and verifier criteria never count as "
                     f"'points to fix'. No Teams post for an approval. No Astra rounds. End-of-task report.\n\n{body}")
                time.sleep(1)
                cmux("send-key", "--surface", surf, "Enter")
        else:
            log(f"comments: {len(new)} new review feedback on PR #{n} {card}; no workspace open -> TRIAGE.md")
            if not DRY:
                with open(os.path.expanduser("__PROJECT_DIR__/inbox/TRIAGE.md"), "a") as f:
                    f.write(f"\n- [NEW] {time.strftime('%Y-%m-%d %H:%M')} reviewer feedback on PR #{n} ({card}); "
                            f"no workspace open (reopen with task_open.sh {card}).\n{body}\n")
        if not DRY:
            seen[n] += [k for k, _ in new]
    if not DRY:
        json.dump(seen, open(SEEN, "w"), indent=1)


def one_pass():
    pulls = gh_pulls()
    if pulls is None:
        log("gh failed; skipping pass")
        return
    hold = set(open(HOLD).read().split()) if os.path.exists(HOLD) else set()
    st = load(STATE, {})
    for w in json.loads(cmux("tree", "--json"))["windows"][0]["workspaces"]:
        m = re.search(r"^[A-Z]{3}\b.*?(01A-\d+)", w["title"])
        if not m:
            continue
        card, ref, title = m.group(1), w["ref"], w["title"]
        hits = [p for p in pulls if re.search(rf"\b{card}\b", p["title"] + " " + p["headRefName"], re.I)]
        if not hits:
            continue
        hits.sort(key=lambda p: (p["state"] != "OPEN", -p["number"]))
        want = hits[0]
        side = cmux("sidebar-state", "--workspace", ref)
        # 1. badge
        cur = re.search(r"^pr=#(\d+) (\w+)", side, re.M)
        if not (cur and int(cur.group(1)) == want["number"] and cur.group(2).upper() == want["state"]):
            was = f"#{cur.group(1)} {cur.group(2)}" if cur else "none"
            log(f"badge {title}: {was} -> #{want['number']} {want['state'].lower()} ({want['headRefName']})")
            if not DRY:
                cmux("pr", str(want["number"]), "--workspace", ref, cwd=REPO_DIR)
        # 2. auto-close
        if want["state"] != "MERGED" or card in hold:
            st.pop(ref, None)
            continue
        idle = "claude_code=Idle" in side
        surf = next((p["surfaces"][0]["ref"] for x in [w] for p in x.get("panes", []) if p.get("surfaces")), None)
        rec = st.get(ref)
        sm = os.path.join(HANDOFFS, card, "STATE.md")
        if rec is None:
            if not idle or not surf:
                continue
            log(f"close {title}: PR #{want['number']} merged; asking for STATE.md hand-off")
            if not DRY:
                cmux("send", "--surface", surf, "--paste",
                     f"Captain auto-close: PR #{want['number']} for {card} is merged. Write or update "
                     f"drafts/handoffs/{card}/STATE.md (<40 lines: outcome, merge commit, card state, anything still "
                     f"open and who it waits on, files). No posts, no card moves. Reply HANDOFF-DONE when saved. "
                     f"This workspace closes after that.")
                time.sleep(1)
                cmux("send-key", "--surface", surf, "Enter")
                st[ref] = {"card": card, "asked": time.time()}
        else:
            age = time.time() - rec["asked"]
            fresh = os.path.exists(sm) and os.path.getmtime(sm) > rec["asked"]
            if fresh and idle:
                log(f"close {title}: STATE.md saved; closing")
                if not DRY:
                    cmux("workspace", "close", "--workspace", ref, "--force")
                st.pop(ref, None)
            elif age > 45 * 60 and not rec.get("gave_up"):
                log(f"close {title}: no STATE.md after 45 min; leaving open")
                rec["gave_up"] = True
    watch_comments(pulls)
    if not DRY:
        json.dump(st, open(STATE, "w"), indent=1)


log(f"ws_sync start (dry={DRY}); hold list {HOLD}")
while True:
    try:
        one_pass()
    except Exception as e:
        log(f"error: {e}")
    if ONCE:
        break
    time.sleep(120)
