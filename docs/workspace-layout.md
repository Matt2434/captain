# Workspace layout (cmux sidebar)

```
┌───────────────────────────── cmux sidebar ─────┐
│ 📌 🤠 Captain            ← pinned, always top   │
│    MAT 🛠️ 01A-263 CI fix   [PR #173]            │
│    TM1 🔍 01A-258          [PR #176]            │
│    MAT ✍️ 01A-238 Deck outline                  │
│    ...                                          │
│    ☕                     ← caffeinate, bottom   │
└─────────────────────────────────────────────────┘
```

- **🤠 Captain** is the coordinator agent. It is pinned at the top. Its right pane is a plain local terminal (never the VM). Start it from your project folder so its own sidebar badge doesn't show another repo's PR.
- **Task workspaces** sit in the middle, one per card or review. Left pane: a Claude session. Right pane: an SSH shell on the team VM (or a local viewer for writing tasks).
- **☕** sits at the bottom and runs `caffeinate -dimsu`, so the Mac doesn't sleep and kill long runs.

`setup.py` enforces all of this every time you run `/captain`; it's safe to run again.

## Lifecycle of a task workspace

1. Captain opens it (`cmux new-workspace`), splits right, SSHes the right pane, launches `claude`, pastes the prompt.
2. The session works and ends with the End-of-task report.
3. Before closing, it writes `drafts/handoffs/<card>/STATE.md`.
4. After the PR merges, `ws_sync.py` closes it (unless the card is on the hold list `~/.config/capstone-autoclose-hold.txt`).
5. To come back: `task_open.sh <card> <emoji> "<label>"`. A fresh session reads only STATE.md and the live PR/card.
