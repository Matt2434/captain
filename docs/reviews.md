# Review pipeline

## Trigger

A review starts only when your school GitHub account is **requested or re-requested** as reviewer. New commits alone don't start one. `watch_prs.py` checks every 60 s and opens (or reuses) the workspace for that card.

## Steps a review session follows

1. **Reviewer check.** If someone else is the requested reviewer or named verifier, stop and tell the user. If they still want it, it's an "extra review": comment only, no Approve/Request changes.
2. **Read** the live card, its exit criteria and the PR diff. If the author posted a Teams message about the work, treat each claim as something to verify (confirmed / contradicted / not verified).
3. **Test locally, then on the VM** in a separate worktree (`git worktree add ~/prNN-wt <sha>`). Never change the VM's main checkout. Run `vm_ensure.sh` first.
4. **Verdict per criterion**, with `file:line` evidence.
5. **Post, in order:**
   - GitHub: a formal review (`APPROVE` or `REQUEST_CHANGES`) with inline comments and ```suggestion``` blocks, then a detailed summary comment written for a coding agent to act on.
   - YouTrack: tick every met criterion on the card **first**, then a short comment (format in `templates/comment-format.md`).
   - Mirror the ticks in the PR body checklist.
   - Teams: see `docs/teams.md`.
6. **Card state:** move to **To Verify** if it's In Progress/Open. Done only after every box is ticked on card and PR, the PR is approved, and the user approves the move. Never move a card out of Done.
7. **End-of-task report** (below).

**Approval rule:** "PR merged" and "independent verification" never block approval. A human merges.

## End-of-task report (review shape)

1. Opening line: PR, commit reviewed, verdict, what was posted, who the verifier/requested reviewer is.
2. `Test results` table (rows = checks; columns = Local, VM), then VM status, CI status, live API calls sent or not.
3. `What I asked <author> to fix`: one bullet per fix with `file:line`.
4. `Things you should know`.
5. Saved review path, then `Links:`.

## Fixing review feedback on your own PR

Fix every point → push → confirm CI → reply on the PR (what changed per point, commit sha, verify command) → re-request the reviewer (`gh api -X POST repos/<repo>/pulls/<n>/requested_reviewers -f "reviewers[]=<login>"`). If any point is deferred or disputed, ask before re-requesting.
