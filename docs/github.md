# GitHub setup

1. Create (or use) a **school-only** GitHub account. Never push school work from a personal account.
2. `gh auth login` for it. If you have both accounts: `gh auth status`, then `gh auth switch -u <school>` before any push or `gh` command. Put this rule in your global `~/.claude/CLAUDE.md`.
3. In the project folder: `git config user.email <school email>` so commits are attributed correctly.
4. New personal repos for the project: `gh repo create <school>/<name> --private`.
5. Check scopes before editing workflow files: `gh auth status` should list `workflow`.

## PR format

- Branch `<card>-<description>` from current `origin/main`, in a new worktree. Keep other worktrees and uncommitted work.
- PR body: YouTrack link, Summary, Files, `## Exit criteria` copied from the live card as checkboxes, `## Verification` with commands, results, evidence paths.
- Tick only criteria backed by executed evidence. Independent verification stays unticked until the named teammate does it.
- Add the named verifier as reviewer as soon as the PR opens: `gh pr edit <n> --add-reviewer <login>`. Keep a YouTrack-login → GitHub-login table in `CLAUDE.md`.
- No "Generated with Claude Code" footer or Co-Authored-By trailer (personal preference; drop this if you don't mind).

## CI

Team org had Actions disabled, so CI runs on a school VM as a systemd timer that polls PRs and posts a `team/local-ci` status. If yours does too, keep its controller separate from PR code and never copy PR code over it.
