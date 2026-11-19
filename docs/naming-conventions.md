# Naming conventions

| Thing | Format | Example |
|---|---|---|
| Workspace | `<OWNER> <emoji> <card> [label]` | `MAT 🔍 01A-215`, `PRA 🛠️ 01A-263 CI fix` |
| Deck workspace | `<OWNER> <📈/📉> <Deck> <MM-DD> · S<sprint>W<week>` | `MAT 📈 Status Deck 11-09 · S4W3` |
| Branch | `<card>-<short-kebab-description>` from current `origin/main`, in its own worktree | `01A-119-climategpt-api-validation` |
| PR title | `<card>: <concrete deliverable>` | `01A-119: Validate ClimateGPT API responses` |
| Worktree folder | `<repo>-<card>[-review]` | `team-repo-216-review` |
| Issue doc | `corpus/issues/<card> <Title>.md` (one master, edited in place; PDF next to it) | `01A-24 Data Sources.md` |
| Old versions | `corpus/issues/iterations/<name> - vN.md` | |
| Status report | `inbox/status/STATUS-YYYY-MM-DD_HH-MM-SS.md` (never overwrite) | |
| Hand-off | `drafts/handoffs/<card>/STATE.md` | |
| Saved review | `drafts/reviews/<card>/...` (short sha in the name) | |
| Meeting transcript | `corpus/transcripts/YYYY-MM-DD HHMM - <Meeting>.md` | |

**Owner codes:** the first three letters of the author's first name (`MAT`, `PRA`, `POO`…). Set them in `OWNER` in `watch_prs.py`.

**Emoji:** ✍️ writing · 🔍 review · 🛠️ code · 🧪 evaluation/test run · 📊 analysis · 📽️ deck · 📈 status deck · 📉 partner deck.

No PR number in workspace names; cmux shows it as a badge.
