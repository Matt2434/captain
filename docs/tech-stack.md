# Tech stack and models

## Breakdown

| Layer | Tool | What it does in this system | How it is used |
|---|---|---|---|
| Terminal | **cmux** | Holds every session as a workspace in a sidebar; split panes; scriptable from the CLI | Captain drives it with `cmux tree`, `new-workspace`, `new-split right`, `send --paste`, `send-key Enter`, `read-screen`, `pr <n>` (PR badge), `workspace-action pin` |
| Agent | **Claude Code** | The Captain and every task/review session | `/captain` skill in the pinned workspace; task sessions launched with a model + effort flag |
| Second opinion | **Codex CLI / Astra** | Independent review pass with a different model family; a one-shot helper that approves the Duo push through iPhone Mirroring | `codex exec --ephemeral "<prompt>"`; `astra_view.sh <worktree>` shows its live output |
| Code host | **GitHub + gh** | PRs, formal reviews, reviewer requests, CI status | Always the school account; `gh auth switch -u <school>` before any push |
| Tracker | **YouTrack** (REST API) | Cards, exit criteria, states (Open → In Progress → To Verify → Done) | Token in `.env`; `status.py` reads it; poller snapshots the board every 10 min |
| Chat | **Microsoft Teams** | Group chat and 1:1 review messages | `scripts/pw/teams-send.mjs` / `teams-dm.mjs` (headless Chrome, saved login) |
| Files | **SharePoint** | Shared docs and decks; your DRAFTS folder | `sp-upload.mjs`, `sp-download.mjs`, `sp-list.mjs` |
| Test host | **School VM** over **Cisco VPN + Duo** | CI and PR test runs | Right-hand pane of each task workspace; `vm_ensure.sh` |
| Keep-awake | **caffeinate** | Stops the Mac sleeping while sessions run | `caffeinate -dimsu` in the ☕ workspace |
| Personal tasks | **Linear** (optional) | Your own to-do board and review follow-ups | Claude's Linear connector |

## Models

| Job | Model | Effort | Why |
|---|---|---|---|
| Captain (coordinator) | Claude Opus 5.5 | default | Long context, keeps many workspaces straight |
| Task work (code, writing, analysis) | Claude Opus 5.5 | low | Fast and cheap enough to run several at once |
| **PR reviews and re-reviews** (most used) | **Claude Fable 5.2** | low | Best at checking each exit criterion against evidence; the default for every review since 10 Nov |
| Deck reviews | Claude Opus 5.5 | low | Better with slides and rubric wording |
| Second-opinion review | Astra (via Codex) | low | Different model family catches different things |

Change these in Part 2 of `SKILL.md`.
