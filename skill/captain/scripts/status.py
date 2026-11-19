#!/usr/bin/env python3
"""Captain status: project + GitHub account first, then YouTrack and GitHub summaries."""
import json, os, subprocess, urllib.parse, urllib.request
REPO = "__GH_REPO__"
env = {}
for l in open(os.path.expanduser("~/.config/capstone.env")):
    if "=" in l and not l.startswith("#"):
        k, v = l.strip().split("=", 1); env[k] = v.strip().strip('"\'')
yt, tok = env["YOUTRACK_URL"].rstrip("/"), env["YOUTRACK_TOKEN"]

def gh(*a):
    return subprocess.run(["gh", *a], capture_output=True, text=True).stdout

subprocess.run(["gh", "auth", "switch", "-u", "__GH_USER__"], capture_output=True)
acct = gh("api", "user", "--jq", ".login").strip()
print("Project: __PROJECT_DIR__")
print(f"GitHub account: {acct or 'UNKNOWN'}{'' if acct == '__GH_USER__' else '  <-- expected __GH_USER__'}")

def issues(q):
    u = yt + "/api/issues?" + urllib.parse.urlencode({"query": q, "$top": 100,
        "fields": "idReadable,summary,description,customFields(name,value(name,login))"})
    return json.load(urllib.request.urlopen(urllib.request.Request(u, headers={"Authorization": "Bearer " + tok})))

def field(i, n):
    for c in i["customFields"]:
        if c["name"] == n:
            v = c["value"]; return (v or {}).get("name") or (v or {}).get("login") if isinstance(v, dict) else v
def crit(i):
    d = i.get("description") or ""; return d.count("* [x]"), d.count("* [x]") + d.count("* [ ]")

print("\n## YouTrack - my cards (__SCHOOL_USER__, unresolved)")
for i in sorted(issues("Assignee: __SCHOOL_USER__ #Unresolved"), key=lambda i: str(field(i, "State"))):
    x, n = crit(i)
    print(f"- {i['idReadable']} [{field(i,'State')}] {x}/{n} criteria - {i['summary'][:70]}")
print("\n## YouTrack - waiting on my verification (To Verify, Verifier: __SCHOOL_USER__)")
tv = [i for i in issues("State: {To Verify}") if "@__SCHOOL_USER__" in (i.get("description") or "").split("Verifier")[-1]]
for i in tv:
    print(f"- {i['idReadable']} ({field(i,'Assignee')}) - {i['summary'][:70]}")
if not tv: print("- none")

print("\n## GitHub - my open PRs")
for p in json.loads(gh("pr", "list", "-R", REPO, "--author", "@me", "--json",
        "number,title,isDraft,reviewDecision,reviewRequests,statusCheckRollup") or "[]"):
    ci = ",".join((c.get("state") or c.get("conclusion") or "?") for c in p["statusCheckRollup"]) or "none"
    rev = ",".join(r.get("login", "") for r in p["reviewRequests"]) or "-"
    print(f"- #{p['number']} {'[draft] ' if p['isDraft'] else ''}{p['title'][:60]} | CI {ci} | review {p['reviewDecision'] or 'pending'} ({rev})")
print("\n## GitHub - PRs requesting my review")
rq = json.loads(gh("pr", "list", "-R", REPO, "--search", "review-requested:@me", "--json", "number,title,author") or "[]")
for p in rq: print(f"- #{p['number']} {p['title'][:60]} ({p['author']['login']})")
if not rq: print("- none")
