# YouTrack setup

1. YouTrack → Profile → Account Security → **New token** (scope: YouTrack).
2. Save it in `__PROJECT_DIR__/.env` as `YOUTRACK_TOKEN=...` and `chmod 600 .env`. If a LaunchAgent polls the board, keep a copy in `~/.config/capstone.env` (launchd can't read `~/Desktop` on macOS).
3. Optional poller: `scripts/poll-youtrack.sh` every 10 min (LaunchAgent) writes `corpus/youtrack/BOARD.md` + `issues.json` and flags changes.

## Rules

- **States:** start your own task → **In Progress**. All criteria met except independent verification → open the PR, tick the criteria, comment, move to **To Verify**. Your own cards stop there; the verifier closes them.
- **Ticks live on the card** (`* [ ]` → `* [x]`), never restated in a comment. Tick before (or with) the YouTrack comment.
- **Comment format** (`templates/comment-format.md`):
  ```
  <Status statement>: [PR #n — title](link)

  Location: <branch + files, or Teams > ... path>. <one-line summary>

  Still needed before merge:
  - <one action per bullet>
  ```
- Link first, then `Location:`, then bullets of what's still left. No prose blobs.
- Card content (new stories/tasks) follows `templates/user-story-format.md` and `templates/task-format.md`. Draft them in `drafts/`; don't create cards without approval.
- Don't edit teammates' cards except to tick criteria a review found met.
