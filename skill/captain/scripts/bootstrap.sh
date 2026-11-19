#!/usr/bin/env bash
# Captain bootstrap (pattern adapted from kunchenguid/firstmate bin/fm-bootstrap.sh).
#
# Usage:
#   bootstrap.sh                 Detect. Prints one line per problem, nothing when all is well. Always exits 0.
#   bootstrap.sh install <tool>  Install the named tools. Only run for tools the user approved.
#
# Detect lines (the /captain skill reads these and asks the user):
#   MISSING: <tool> (purpose: <why>; install: <command>)
#   OPTIONAL_MISSING: <tool> (purpose: <why>; install: <command>)
#   MISSING_MANUAL: <tool> (purpose: <why>; instructions: <url>)
#   NEEDS_CONFIG: <what>                 placeholders not filled in, or config file missing
#   NEEDS_GH_AUTH                        gh is not logged in
#   NEEDS_GH_ACCOUNT: <login>            the school GitHub account is not logged in to gh
#   NEEDS_REPO_ACCESS: <org/repo>        that account cannot read the team repo
#   NEEDS_YOUTRACK_TOKEN: <file>         no YOUTRACK_URL / YOUTRACK_TOKEN in the file
#   YOUTRACK_TOKEN_INVALID: <http code>  token rejected by the YouTrack API
#   NEEDS_MS_LOGIN: <profile dir>        no saved Microsoft login for Teams/SharePoint scripts
#   VM_UNREACHABLE: <host>               VM not reachable (VPN off?); VM tests will be "not verified"
set -u
GH_USER="__GH_USER__"; GH_REPO="__GH_REPO__"; VM_HOST="__VM_HOST__"
ENVF="$HOME/.config/capstone.env"; PWPROFILE="$HOME/.local/share/capstone/pw-profile"

purpose() {
  case "$1" in
    claude) echo "runs Captain and every task session" ;;
    cmux) echo "workspaces, split panes, sending prompts to sessions" ;;
    gh) echo "PRs, reviews, reviewer requests" ;;
    git) echo "worktrees, one per task" ;;
    python3) echo "Captain layout/status/watcher scripts" ;;
    node) echo "Teams and SharePoint scripts" ;;
    playwright) echo "headless Chrome for Teams/SharePoint" ;;
    jq) echo "reading JSON from gh and cmux in scripts" ;;
    codex) echo "Astra second-opinion reviews and the Duo helper" ;;
    glow) echo "showing markdown in a side pane" ;;
    pandoc) echo "markdown to PDF/DOCX for documents" ;;
    vpn) echo "Cisco Secure Client CLI for the school VPN" ;;
  esac
}
install_cmd() {
  case "$1" in
    gh|git|python3|node|jq|glow|pandoc) echo "brew install ${1/python3/python}" ;;
    cmux) echo "brew install --cask cmux" ;;
    claude) echo "npm install -g @anthropic-ai/claude-code" ;;
    codex) echo "npm install -g @openai/codex" ;;
    playwright) echo "npm install -g playwright && npx playwright install chromium" ;;
    *) return 1 ;;
  esac
}
manual_url() {
  case "$1" in
    vpn) echo "your school IT portal (Cisco Secure Client); see docs/vpn-phone.md" ;;
    brew) echo "https://brew.sh" ;;
  esac
}
has() { command -v "$1" >/dev/null 2>&1; }
missing() { echo "${2:-MISSING}: $1 (purpose: $(purpose "$1"); install: $(install_cmd "$1"))"; }

if [ "${1:-}" = install ]; then
  shift; [ $# -gt 0 ] || { echo "usage: bootstrap.sh install <tool>..."; exit 2; }
  has brew || { echo "MISSING_MANUAL: brew (instructions: $(manual_url brew))"; exit 1; }
  for t in "$@"; do
    c=$(install_cmd "$t") || { echo "no automatic install for $t"; continue; }
    echo "==> $t: $c"; bash -c "$c" && echo "ok: $t" || echo "FAILED: $t"
  done
  exit 0
fi

# 1. Tools
for t in claude cmux gh git python3 node; do has "$t" || missing "$t"; done
has node && { node -e "require.resolve('playwright')" >/dev/null 2>&1 || npm ls -g playwright >/dev/null 2>&1 || missing playwright; }
for t in jq codex glow pandoc; do has "$t" || missing "$t" OPTIONAL_MISSING; done
[ -n "$VM_HOST" ] && [[ "$VM_HOST" != *__* ]] && [ ! -x /opt/cisco/secureclient/bin/vpn ] && echo "MISSING_MANUAL: vpn (purpose: $(purpose vpn); instructions: $(manual_url vpn))"

# 2. Config filled in
case "$GH_USER$GH_REPO$VM_HOST" in *__*) echo "NEEDS_CONFIG: placeholders not replaced; fill config/captain.env and rerun install.sh" ;; esac

# 3. GitHub
if has gh; then
  if ! gh auth status >/dev/null 2>&1; then echo "NEEDS_GH_AUTH"
  elif ! gh auth status 2>&1 | grep -q "account $GH_USER"; then echo "NEEDS_GH_ACCOUNT: $GH_USER"
  else
    gh auth switch -u "$GH_USER" >/dev/null 2>&1
    gh repo view "$GH_REPO" --json name >/dev/null 2>&1 || echo "NEEDS_REPO_ACCESS: $GH_REPO"
  fi
fi

# 4. YouTrack
YT_URL=$(grep -s '^YOUTRACK_URL=' "$ENVF" | cut -d= -f2- | tr -d "\"'")
YT_TOK=$(grep -s '^YOUTRACK_TOKEN=' "$ENVF" | cut -d= -f2- | tr -d "\"'")
if [ -z "$YT_URL" ] || [ -z "$YT_TOK" ]; then echo "NEEDS_YOUTRACK_TOKEN: $ENVF"
else
  code=$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: Bearer $YT_TOK" "${YT_URL%/}/api/users/me?fields=login")
  [ "$code" = 200 ] || echo "YOUTRACK_TOKEN_INVALID: $code"
fi

# 5. Microsoft login for Teams/SharePoint
[ -d "$PWPROFILE" ] || echo "NEEDS_MS_LOGIN: $PWPROFILE"

# 6. VM (information only)
if [ -n "$VM_HOST" ] && [[ "$VM_HOST" != *__* ]]; then nc -z -G 4 "$VM_HOST" 22 >/dev/null 2>&1 || echo "VM_UNREACHABLE: $VM_HOST"; fi
exit 0
