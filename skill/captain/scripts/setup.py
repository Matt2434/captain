#!/usr/bin/env python3
"""Captain layout: pin Captain, ensure caffeinate, ssh every task VM pane. Idempotent."""
import json, os, re, socket, subprocess, time
os.environ["CMUX_QUIET"] = "1"
VM = "__SCHOOL_USER__@__VM_HOST__"
SSH = f"ssh -o ServerAliveInterval=30 {VM}"
WORK = re.compile(r"^(Captain|🤠 Captain|[A-Z]{3}\b|Issue|Review)")

def cmux(*a):
    return subprocess.run(["cmux", *a], capture_output=True, text=True).stdout

def tree():
    return json.loads(cmux("tree", "--json"))

def screen(s):
    return [l for l in cmux("read-screen", "--surface", s).splitlines() if l.strip()]

def send(s, text):
    cmux("send", "--surface", s, text); cmux("send-key", "--surface", s, "Enter")

def vm_reachable():
    try:
        socket.create_connection(("__VM_HOST__", 22), timeout=5).close(); return True
    except OSError:
        return False

d = tree(); caller = d["caller"]["workspace_ref"]
wss = d["windows"][0]["workspaces"]
CAP_TITLE = "🤠 Captain"
cap = next((w for w in wss if w["title"] == CAP_TITLE), None) or next((w for w in wss if re.match(r"^(Captain|🤠)", w["title"])), None)
if not cap:
    cap = next(w for w in wss if w["ref"] == caller)
if cap["title"] != CAP_TITLE:
    cmux("rename-workspace", "--workspace", cap["ref"], CAP_TITLE)
if not cap["pinned"]:
    cmux("workspace-action", "--workspace", cap["ref"], "--action", "pin")
cmux("workspace-action", "--workspace", cap["ref"], "--action", "move-top")
print(f"Captain: {cap['ref']} pinned")

caf_running = subprocess.run(["pgrep", "-f", "caffeinate -dimsu"], capture_output=True).returncode == 0
caf = next((w for w in wss if w["title"].strip() in ("☕", "caffeinate ☕")), None)
if not caf:
    cmux("new-workspace", "--name", "☕", "--command", "caffeinate -dimsu", "--focus", "false")
    print("☕: created (caffeinate -dimsu)")
elif not caf_running:
    s = caf["panes"][0]["surfaces"][0]["ref"]; send(s, "caffeinate -dimsu")
    print("☕: restarted")
else:
    print("☕: running")
# Rule (Matt, 8 Nov): caffeinate workspace always sits at the bottom.
wss2 = tree()["windows"][0]["workspaces"]
caf2 = next((w for w in wss2 if w["title"].strip() in ("☕", "caffeinate ☕")), None)
if caf2:
    cmux("reorder-workspace", "--workspace", caf2["ref"], "--index", str(len(wss2) - 1))
    print("☕: moved to bottom")

vpn = vm_reachable()
print(f"VM {VM}: {'reachable' if vpn else 'UNREACHABLE - connect the GMU VPN, then rerun /captain'}")
for w in tree()["windows"][0]["workspaces"]:
    if not WORK.match(w["title"]):
        continue
    if len(w["panes"]) < 2:
        cmux("new-split", "right", "--workspace", w["ref"], "--focus", "false"); time.sleep(1)
        w = next(x for x in tree()["windows"][0]["workspaces"] if x["ref"] == w["ref"])
    s = w["panes"][-1]["surfaces"][0]["ref"]
    if "Captain" in w["title"]:
        print(f"Local pane {w['title']:<20} {s}: plain terminal, no VM")
        continue
    tail = screen(s)[-3:]
    tty = w["panes"][-1]["surfaces"][0].get("tty") or ""
    on_vm = bool(tty) and "ssh" in subprocess.run(["ps", "-t", tty.replace("/dev/", ""), "-o", "comm="], capture_output=True, text=True).stdout
    if on_vm or any("@__VM_HOSTNAME__" in l for l in tail):
        state = "logged in"
    elif not vpn:
        state = "not logged in (VPN down)"
    elif tail and re.search(r"(matt@|[%$#❯>]\s*$)", tail[-1]) and "@__VM_HOSTNAME__" not in tail[-1]:
        send(s, SSH); state = "ssh sent"
    else:
        state = "busy or unknown, left alone"
    print(f"VM pane  {w['title']:<22} {s}: {state}")

# Sidebar PR badge: every run, point each "CAP … 01A-N" workspace at its card's current PR (from GitHub,
# not cmux's cached state): the open PR naming the card in its title/branch, else the newest one.
# If the card moves to a new PR/branch, the badge is moved; the state shown is refreshed on each attach.
REPO_DIR = os.path.expanduser("__PROJECT_DIR__/__REPO_CHECKOUT__")
if os.path.exists(os.path.join(REPO_DIR, ".git")):
    pulls = None
    for w in json.loads(cmux("tree", "--json"))["windows"][0]["workspaces"]:
        m = re.search(r"^[A-Z]{3}\b.*?(01A-\d+)", w["title"])
        if not m:
            continue
        if pulls is None:
            o = subprocess.run(["gh", "pr", "list", "-R", "__GH_REPO__", "--state", "all", "--limit", "200",
                                "--json", "number,title,headRefName,state"], capture_output=True, text=True)
            pulls = json.loads(o.stdout) if o.returncode == 0 else []
        card = m.group(1)
        hits = [p for p in pulls if re.search(rf"\b{card}\b", p["title"] + " " + p["headRefName"], re.I)]
        hits.sort(key=lambda p: (p["state"] != "OPEN", -p["number"]))
        if not hits:
            continue
        want = hits[0]
        cur = re.search(r"^pr=#(\d+) (\w+)", cmux("sidebar-state", "--workspace", w["ref"]), re.M)
        if cur and int(cur.group(1)) == want["number"] and cur.group(2).upper() == want["state"]:
            continue
        r = subprocess.run(["cmux", "pr", str(want["number"]), "--workspace", w["ref"]], cwd=REPO_DIR, capture_output=True, text=True)
        was = f"#{cur.group(1)} {cur.group(2)}" if cur else "none"
        print(f"PR badge  {w['title']}: {was} -> " + (f"#{want['number']} {want['state'].lower()} ({want['headRefName']})" if r.returncode == 0 else r.stderr.strip()[:80]))
