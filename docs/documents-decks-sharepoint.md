# Documents, decks and SharePoint

## Where files go

- Default upload folder: `/sites/__SP_SITE_NAME__/Shared Documents/DRAFTS/__YOUR_FOLDER__/` (one subfolder per teammate).
- Never link a local-only file in a comment. Upload it first and link the SharePoint copy (`LinkingUrl`, spaces as `%20`).
- Every SharePoint link you're given: download a dated snapshot into `corpus/`, add a row to `corpus/sharepoint/LINKS.md` (newest first).

```bash
node scripts/pw/sp-upload.mjs <file> [server-relative folder]   # overwrites; set overwrite=false for new files
node scripts/pw/sp-download.mjs "<server-relative path>" <out>
node scripts/pw/sp-list.mjs "<server-relative folder>"
```

Moving files: download → upload to the new folder → confirm → delete the old copy only with the owner's OK. Renames keep the team's naming rules.

## Documents

- One master markdown per card: `corpus/issues/<card> <Title>.md`, edited in place. Version only when asked (old copy to `iterations/`).
- Structure: YAML (date/sprint/issue/type/status/author) → title → Description → Exit Criteria (checkboxes) → one section per criterion → Findings/Open items → Sources as `[^N]` footnotes.
- Output is PDF: `scripts/md2pdf.sh <file>` (Georgia serif, blue `#1a4f8a` headings, italic author byline). Upload the PDF.
- `.docx` only when the team template needs Word.

## Decks (PowerPoint)

- Each deck gets a workspace (`MAT 📈 Status Deck 11-09 · S4W3`) and a memory folder `drafts/reviews/decks/<slug>/STATE.md`: deck, SharePoint link, local .pptx, rubric, artifact URL, slide-by-slide changes (done/pending/dropped).
- Review against this week's work, the assignment rubric, the team template and file naming.
- Change lists go in one minimal white Artifact per deck. Don't edit the .pptx or post until approved.
- After a deck is created/updated for your card: upload to DRAFTS and comment on the card with the link first.
- Architecture diagrams: check them against the code and cite your reference article.
