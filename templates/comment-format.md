---
date: 2026-09-02
updated: 2026-09-30
type: format
---

# YouTrack comment format (Matt's convention)

Derived from the 01A-24 and 01A-22 comments; bullet + card-checkbox rule added 2026-09-30 after the 01A-82 review. Comments are Markdown in YouTrack.

```
<Status statement>: [<PR #n — title> or <Document name>](<link>)

Location: <branch + files, or Teams > ... path>. <One line: what was checked / covered, CI result, "exit criteria ticked on the card".>

Still needed before merge:        (or "Still needed before close:" / "Open items:")
- <one concrete thing left to do>
- <...>

Optional before merge:            (omit if none)
- <polish item>

Note: <anything the reader must act on or watch out for.>
```

## Rules

- **The link goes on the very first line**, as the PR or document name after a colon. For a card with a PR, link the PR; link the document only when there is no PR.
- The first line is a **status statement / verdict**, not a label ("Reviewed as US3 owner — approve after the items below", "Findings documented and available for team review", "CI workflow implemented — ready for review").
- **Second block always starts `Location:`** — the branch and files, or the Teams path in `>` form (`Teams > A. Team Aurora > Shared > DRAFTS > __YOUR_FOLDER__`) — then a one-line summary in the same paragraph.
- **Exit criteria are ticked on the card, not in the comment.** Edit the card description and flip `* [ ]` to `* [x]` for each satisfied criterion. Leave unsatisfied ones unticked. Never paste the criteria list into the comment.
- **Body bullets = what still needs to be done.** One bullet per remaining item, phrased as an action ("Fix the coverage wording to ...", "Add the `nonfinite` reason ..."). For every unticked criterion, add a bullet saying what would satisfy it. Keep each bullet to one or two lines. Never a prose blob.
- Close with `Note:` only when something needs action or watching.
- **Always link the document.** If a link is not already provided or in SharePoint, upload the file to the default Teams location first (`/sites/__SP_SITE_NAME__/Shared Documents/DRAFTS/__YOUR_FOLDER__/`) and link that copy. Never reference a file that only exists locally.
- Get the link from the file's `LinkingUrl` (REST: `.../Files?$select=Name,LinkingUrl`) and percent-encode spaces as `%20`.
- **Two audiences (2026-10-06):** the YouTrack comment is very concise (humans skim it); the GitHub PR comment is detailed and written for an LLM/coding agent to act on (per-criterion verdict, `file:line` fixes with expected behaviour, verify commands). Always post both.
- **Mirror on GitHub.** When the card has a PR, also post a review comment on the PR (as __GH_USER__) with the YouTrack card linked on its first line, bullets split into "What checks out", "Fixes before merge", "Optional polish".

## API notes

- Comment: `POST /api/issues/<id>/comments` with `{"text": ..., "usesMarkdown": true}`; edit with `POST /api/issues/<id>/comments/<commentId>`.
- Tick criteria: `GET /api/issues/<id>?fields=description`, replace `* [ ]` → `* [x]` on the satisfied lines only, `POST /api/issues/<id>` with `{"description": ...}`.

## Reference example (2026-09-30, 01A-82)

> Reviewed as US3 owner — approve after the items below: [PR #53 — 01A-82 GSA MCP tool description](https://github.com/__GH_REPO__/pull/53)
>
> Location: branch `01A-82-gsa-mcp-tool-description` → `docs/mcp/01A-82-gsa-tool-description.md` + README section. Checked against server, adapter, schema, data dictionary and limitations record. Local CI passed. Exit criteria ticked on the card.
>
> Still needed before merge:
> - Fix the coverage wording to match the limitations record: 65N only west of 40E, 60N across Siberia, Iceland absent.
> - Add the `nonfinite` reason next to `masked_in_bounds`.
> - Add a one-line pointer from the field table to `docs/data_dictionary.md` so the "traced to the data dictionary" criterion can be ticked.
>
> Optional before merge:
> - Name the machine-readable form (tool docstrings in `src/mcp/server.py`); own README heading; blank line before "Returned Record"; merge main.

## Older examples

> Findings documented and available for team review: Review of Existing ClimateGPT/MCP Work (PDF)
>
> Location: Teams > A. Team Aurora > Shared > DRAFTS > __YOUR_FOLDER__. Covers all five exit criteria; prior-semester repository access remains an open item.

> CI workflow implemented — ready for review: PR #1 — Enable CI workflow (lint, format check, unit tests)
>
> Branch feature/01A-22-ci-workflow: adds .github/workflows/ci.yml; flake8 clean, black clean, 6/6 unit tests pass.
>
> Note: GitHub Actions appears disabled on the repository — the instructor needs to enable it.
