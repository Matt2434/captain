#!/bin/bash
# md2pdf.sh <file.md> — render an issue markdown to the standard Capstone PDF
# (Georgia serif, blue headings, author byline from YAML `author:`, superscript footnotes).
# PDF is written next to the .md with the same basename. This is the DEFAULT output
# format for corpus/issues/ documents.
set -euo pipefail
SRC="${1:?usage: md2pdf.sh <file.md>}"
SRC="$(cd "$(dirname "$SRC")" && pwd)/$(basename "$SRC")"
OUT="${SRC%.md}.pdf"
TMP_HTML=$(mktemp -t md2pdf).html

python3 - "$SRC" "$TMP_HTML" <<'PYEOF'
import sys, re, pathlib, markdown
src, out = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
raw = src.read_text()
m = re.match(r'^---\n(.*?)\n---\n', raw, re.S)
yaml_block = m.group(1) if m else ''
body = raw[m.end():] if m else raw
am = re.search(r'^author:\s*(.+)$', yaml_block, re.M)
author = am.group(1).strip() if am else ''
dm = re.search(r'^date:\s*(.+)$', yaml_block, re.M)
date = dm.group(1).strip() if dm else ''
html_body = markdown.markdown(body, extensions=['tables', 'fenced_code', 'footnotes', 'toc'])
# Link exit criterion N to the "## N. ..." heading (Chrome keeps in-page anchors as PDF links).
heads = {m.group(2): m.group(1) for m in re.finditer(r'<h2 id="([^"]+)">\s*(\d+)\.', html_body)}
ec = re.search(r'(<h2 id="exit-criteria">.*?</h2>\s*<ul>)(.*?)(</ul>)', html_body, re.S)
if ec and heads:
    n = [0]
    def link(m):
        n[0] += 1
        hid = heads.get(str(n[0]))
        return f'<li><a class="ec" href="#{hid}">{m.group(1)}</a></li>' if hid else m.group(0)
    items = re.sub(r'<li>(.*?)</li>', link, ec.group(2), flags=re.S)
    html_body = html_body[:ec.start(2)] + items + html_body[ec.end(2):]
# resolve relative image paths against the markdown's own directory (the temp HTML lives in /tmp)
def _abs(m):
    s = m.group(1)
    if s.startswith(('http://', 'https://', 'file://', 'data:', '/')): return m.group(0)
    return f'src="file://{src.parent / s}"'
html_body = re.sub(r'src="([^"]+)"', _abs, html_body)
if author:
    byline = f'<p class="byline">{author}' + (f' &middot; {date}' if date else '') + '</p>'
    html_body = re.sub(r'(</h1>)', r'\1' + byline, html_body, count=1)
out.write_text(f"""<meta charset="utf-8">
<style>
body {{ font-family: Georgia, serif; max-width: 7in; margin: 0.6in auto; line-height: 1.45; color: #1a1a1a; font-size: 11pt; }}
h1 {{ font-size: 17pt; border-bottom: 2px solid #1a4f8a; padding-bottom: 6px; }}
h2 {{ font-size: 13pt; color: #1a4f8a; margin-top: 1.2em; }}
li {{ margin: 3px 0; }}
table {{ border-collapse: collapse; width: 100%; font-size: 10pt; margin: 0.6em 0; }}
th, td {{ border: 1px solid #bbb; padding: 4px 7px; text-align: left; vertical-align: top; }}
th {{ background: #eef2f7; color: #1a4f8a; }}
sup {{ font-size: 8pt; }}
sup a {{ text-decoration: none; color: #1a4f8a; }}
.footnote {{ font-size: 9.5pt; border-top: 1px solid #ccc; margin-top: 1.5em; }}
.footnote hr {{ display: none; }}
a.footnote-backref {{ display: none; }}
code {{ font-family: Menlo, monospace; font-size: 9pt; background: #f4f4f4; padding: 1px 3px; }}
img {{ max-width: 100%; height: auto; display: block; margin: 0.4em auto; }}
hr {{ border: none; border-top: 1px solid #ccc; }}
a.ec {{ color: inherit; text-decoration: none; border-bottom: 1px dotted #1a4f8a; }}
.byline {{ font-size: 10pt; color: #555; margin-top: -4px; font-style: italic; }}
</style>
<body>{html_body}</body>""")
PYEOF

"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless --disable-gpu \
  --no-pdf-header-footer --print-to-pdf="$OUT" "file://$TMP_HTML" 2>/dev/null
rm -f "$TMP_HTML"
echo "$OUT"
