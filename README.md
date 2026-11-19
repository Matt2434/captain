# Captain

A setup kit for running a team capstone project with one coordinating AI agent, the **Captain**, and one terminal workspace for each task. It contains the instructions, conventions and scripts used by Team Aurora (GMU DAEN-690, Fall 2026) to run reviews, keep YouTrack and GitHub in sync, post to Teams, and make documents and decks.

> The idea of a coordinating "captain" agent that hands work to crew sessions comes from the *First Mate* protocol. This repo is our own take on it, built for a school capstone.

Fork it, fill in `config/captain.env`, run `./install.sh`, and type `/captain` in Claude Code.

---

## Contents

| Path | What it is |
|---|---|
| `skill/captain/SKILL.md` | The `/captain` Claude Code skill. Boilerplate rules first, then a **CUSTOMIZE** section with your own rules |
| `skill/captain/scripts/` | Layout, status, VPN/VM, PR watcher and workspace sync scripts |
| `scripts/` | Markdown → PDF/DOCX, markdown viewer, YouTrack poller |
| `scripts/pw/` | Playwright scripts for Teams (group and 1:1 messages) and SharePoint (upload, download, list); `ms-login.mjs` for the one-time Microsoft sign-in |
| `skill/captain/scripts/bootstrap.sh` | First-run check: missing tools, GitHub and YouTrack access, Microsoft login, VPN. `bootstrap.sh install <tools>` installs the approved ones |
| `templates/` | `CLAUDE.md` project template, YouTrack comment, task and user-story formats |
| `docs/` | One page per topic (list below) |
| `config/captain.env.example` | Every value you need to change, in one file |
| `install.sh` | Copies the skill into `~/.claude/skills/captain` and fills in your values |

Docs:

1. [Tech stack and models](docs/tech-stack.md): cmux, Claude Code, Codex/Astra, which model does what
2. [Workspace layout](docs/workspace-layout.md): Captain pinned at the top, ☕ caffeinate at the bottom, one workspace per task
3. [Naming conventions](docs/naming-conventions.md): workspaces, branches, PRs, files
4. [Review pipeline](docs/reviews.md): how a PR review runs end to end
5. [GitHub setup](docs/github.md)
6. [YouTrack setup](docs/youtrack.md)
7. [Teams messages](docs/teams.md): group chat and personal 1:1 formats
8. [Documents, decks and SharePoint](docs/documents-decks-sharepoint.md)
9. [VPN, Duo and phone setup](docs/vpn-phone.md): iPhone and Android
10. [Known pains](docs/pains.md)

---

## Requirements

### CLIs to install

| Tool | Install (macOS) | Used for | Required? |
|---|---|---|---|
| **Claude Code** (`claude`) | `npm i -g @anthropic-ai/claude-code` | Captain and every task session | Yes |
| **cmux** | https://cmux.dev (app, includes `cmux` CLI) | Workspaces, split panes, sending prompts to sessions, PR badges | Yes |
| **GitHub CLI** (`gh`) | `brew install gh` | PRs, reviews, reviewer requests, CI status | Yes |
| **git** | `xcode-select --install` | Worktrees, one per task | Yes |
| **Python 3.11+** | `brew install python` | `setup.py`, `status.py`, watchers | Yes |
| **Node 20+** | `brew install node` | Playwright scripts for Teams/SharePoint | Yes, for Teams/SharePoint |
| **Playwright** | `npm i -g playwright && npx playwright install chromium` | Headless Chrome with a saved Microsoft login | Yes, for Teams/SharePoint |
| **Codex CLI** (`codex`) | `npm i -g @openai/codex` | Astra second-opinion reviews, the Duo-approval helper | Optional |
| **glow** | `brew install glow` | Showing markdown in a side pane | Optional |
| **pandoc** + a LaTeX/WeasyPrint engine | `brew install pandoc` | `md2pdf.sh`, `md2docx` | For PDF/DOCX output |
| **Cisco Secure Client** | From your school's IT portal | VPN to the school VM | If your CI/VM is behind VPN |
| **Duo Mobile** | App Store / Play Store | VPN two-factor push | If your school uses Duo |
| `caffeinate` | Built into macOS | Keeps the Mac awake while sessions run | Built in |

### Python / Node packages

- Python: standard library only for the Captain scripts. `python-docx` for `docx2md.py` (`pip install python-docx`).
- Node: `playwright`.

### Accounts and access

- A GitHub account for school work only (keep it separate from your personal account), added to the team repo.
- A YouTrack permanent token (Profile → Account Security → New token).
- A Microsoft 365 school login for Teams and SharePoint (you log in once in the Playwright browser profile).
- SSH key access to the team VM, if you run tests there.

---

## Quick start

```bash
gh repo clone <you>/captain && cd captain
cp config/captain.env.example config/captain.env   # fill in your values
./install.sh                                      # installs ~/.claude/skills/captain
cp templates/CLAUDE.md.template "$PROJECT_DIR/CLAUDE.md"   # then edit it
```

1. Open cmux, start a workspace in your project folder, run `claude`.
2. Type `/captain`. The first thing it does is run `bootstrap.sh`. If anything is missing, Captain introduces itself, lists the missing tools (with what each is for and the install command), and asks for your YouTrack token (for your cards and task numbers) and your GitHub login (for your open PRs and review requests). It installs only the tools you approve. Logins and tokens you enter yourself with `!` commands, never in chat. This check is modeled on firstmate's `fm-bootstrap.sh` ([kunchenguid/firstmate](https://github.com/kunchenguid/firstmate)).
3. Once the check passes, it pins the Captain workspace at the top, puts a ☕ caffeinate workspace at the bottom, logs task workspaces into the VM, and reports your cards, PRs and review requests.
4. Ask Captain to start a task or review. It opens a new workspace for it and sends the prompt.

Secrets (`.env`, tokens, VPN passwords) never go in this repo. `config/captain.env` is git-ignored.

---

## Customizing

Everything personal is either in `config/captain.env` or marked `CUSTOMIZE` in `skill/captain/SKILL.md` and `templates/CLAUDE.md.template`. The boilerplate rules (one workspace per task, never post without approval, link-first comments, and so on) are meant to work for any team. Change the rest to fit yours: your tracker, your chat, your naming, your models.
