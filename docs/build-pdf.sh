#!/usr/bin/env bash
#
# build-pdf.sh — maak van qtile-sneltoetsen.md een nette A4-pdf.
#
# Vereist: python3-markdown en Google Chrome (headless).
# Gebruik:  ./docs/build-pdf.sh
#
set -euo pipefail

DOCS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MD="$DOCS_DIR/qtile-sneltoetsen.md"
BUILD="$DOCS_DIR/.build"
HTML="$BUILD/qtile-sneltoetsen.html"
PDF="$DOCS_DIR/qtile-sneltoetsen.pdf"
CHROME="${CHROME:-google-chrome}"

if ! command -v "$CHROME" >/dev/null 2>&1; then
    echo "Fout: $CHROME niet gevonden. Zet CHROME=/pad/naar/chrome." >&2
    exit 1
fi

if ! python3 -c "import markdown" >/dev/null 2>&1; then
    echo "Fout: python3-markdown ontbreekt (sudo apt install python3-markdown)." >&2
    exit 1
fi

mkdir -p "$BUILD"

python3 - "$MD" "$HTML" <<'PY'
from __future__ import annotations

import datetime as dt
import html
import re
import sys
from pathlib import Path

import markdown

src = Path(sys.argv[1])
dst = Path(sys.argv[2])
text = src.read_text(encoding="utf-8")

# De H1 staat al op de cover; verwijder hem uit de body.
text = re.sub(r"\A# .*?\n(?:\s*\n)?", "", text, count=1)

md = markdown.Markdown(extensions=["extra", "toc", "sane_lists"])
body = md.convert(text)
body = body.replace("<p>", '<p class="lead">', 1)
# Houd een paar belangrijke tabellen in één stuk; de overige tabellen mogen
# over een paginagrens doorlopen (met herhaalde kopregel).
for header in ("Onderdeel", "Instelling", "Commando"):
    body = body.replace(
        f"<table>\n<thead>\n<tr>\n<th>{header}</th>",
        f'<table class="keep">\n<thead>\n<tr>\n<th>{header}</th>',
    )

months = [
    "januari", "februari", "maart", "april", "mei", "juni",
    "juli", "augustus", "september", "oktober", "november", "december",
]
today = dt.date.today()
date_nl = f"{today.day} {months[today.month - 1]} {today.year}"

toc_rows = []
for number, token in enumerate(
    [t for t in md.toc_tokens if t["level"] == 2], start=1
):
    toc_rows.append(
        '<li><a href="#{anchor}"><span class="toc-num">{number:02d}</span>'
        "<span>{name}</span></a></li>".format(
            anchor=html.escape(token["id"], quote=True),
            number=number,
            name=html.escape(token["name"]),
        )
    )
toc = "\n".join(toc_rows)

template = """<!doctype html>
<html lang="nl">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Qtile sneltoetsen &amp; begrippen</title>
<style>
:root {{
    --ink: #1d2021;
    --muted: #6d7275;
    --accent: #458588;
    --accent-dark: #32696c;
    --accent-soft: #e6efef;
    --paper: #fbfaf7;
    --line: #dcd7cd;
    --code: #f1eee7;
    --warn: #b1623c;
}}

@page {{
    size: A4;
    margin: 18mm 17mm 18mm;
}}

html {{
    -webkit-print-color-adjust: exact;
    print-color-adjust: exact;
}}

body {{
    margin: 0;
    color: var(--ink);
    background: #fff;
    font-family: "Noto Sans", "DejaVu Sans", sans-serif;
    font-size: 9.6pt;
    line-height: 1.52;
}}

p {{
    margin: 0 0 2.8mm;
    orphans: 3;
    widows: 3;
}}

a {{
    color: var(--accent-dark);
    text-decoration: none;
}}

strong {{
    color: #121516;
}}

code {{
    font-family: "Noto Sans Mono", "DejaVu Sans Mono", monospace;
    font-size: 0.88em;
    background: var(--code);
    border-radius: 1.5mm;
    padding: 0.25mm 1.2mm;
}}

kbd {{
    display: inline-block;
    font-family: "Noto Sans Mono", "DejaVu Sans Mono", monospace;
    font-size: 0.79em;
    line-height: 1.35;
    background: #fff;
    border: 0.25mm solid #cfc9be;
    border-bottom-width: 0.6mm;
    border-radius: 1.2mm;
    padding: 0 1.3mm;
    white-space: nowrap;
    box-decoration-break: clone;
}}

/* ---------- omslag ---------- */

.cover {{
    box-sizing: border-box;
    height: 258mm;
    padding: 22mm 20mm 18mm;
    margin: 0;
    color: #f7f3ea;
    background:
        radial-gradient(circle at 88% 12%, rgba(131, 165, 152, 0.22), transparent 38%),
        radial-gradient(circle at 8% 88%, rgba(69, 133, 136, 0.30), transparent 42%),
        #1d2021;
    border-radius: 4mm;
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    overflow: hidden;
    page-break-after: always;
}}

.cover-top {{
    display: flex;
    justify-content: space-between;
    align-items: baseline;
    border-bottom: 0.35mm solid rgba(247, 243, 234, 0.28);
    padding-bottom: 5mm;
    font-size: 8.4pt;
    letter-spacing: 0.20em;
    text-transform: uppercase;
    color: #b8c8c4;
}}

.cover-top .brand {{
    color: #f7f3ea;
    font-weight: 700;
    letter-spacing: 0.12em;
}}

.cover h1 {{
    margin: 16mm 0 0;
    font-size: 42pt;
    line-height: 1.02;
    letter-spacing: -0.025em;
    font-weight: 700;
}}

.cover h1 span {{
    color: #9fc3bb;
    font-weight: 300;
}}

.cover-sub {{
    margin: 8mm 0 0;
    max-width: 128mm;
    color: #d7dfdc;
    font-size: 12.5pt;
    line-height: 1.45;
}}

.cover-rule {{
    width: 28mm;
    height: 1.2mm;
    margin: 14mm 0 0;
    background: #83a598;
}}

.cover-bottom {{
    display: grid;
    gap: 6mm;
}}

.cover-meta {{
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 5mm;
    border-top: 0.3mm solid rgba(247, 243, 234, 0.22);
    padding-top: 6mm;
}}

.cover-meta div {{
    display: flex;
    flex-direction: column;
    gap: 1.2mm;
}}

.cover-meta span {{
    color: #9aa9a6;
    font-size: 7.6pt;
    letter-spacing: 0.09em;
    text-transform: uppercase;
}}

.cover-meta strong {{
    color: #f7f3ea;
    font-size: 9.4pt;
    font-weight: 500;
}}

.cover-keys {{
    color: #c9d4d1;
    font-size: 8.6pt;
    line-height: 2.0;
}}

.cover-keys kbd {{
    background: rgba(247, 243, 234, 0.08);
    border-color: rgba(247, 243, 234, 0.30);
    color: #f7f3ea;
}}

/* ---------- inhoudsopgave ---------- */

.toc-page {{
    box-sizing: border-box;
    height: 258mm;
    padding-top: 8mm;
    page-break-after: always;
}}

.toc-title {{
    margin: 0 0 9mm;
    font-size: 24pt;
    line-height: 1.1;
    color: var(--accent-dark);
    letter-spacing: -0.02em;
}}

.toc-title::before {{
    content: "";
    display: block;
    width: 18mm;
    height: 1.2mm;
    background: var(--accent);
    margin-bottom: 5mm;
}}

.toc {{
    list-style: none;
    margin: 0;
    padding: 0;
    columns: 1;
}}

.toc li {{
    margin: 0;
    border-bottom: 0.25mm solid var(--line);
}}

.toc a {{
    display: flex;
    align-items: baseline;
    gap: 4mm;
    padding: 2.4mm 0;
    color: var(--ink);
    font-size: 10.4pt;
}}

.toc-num {{
    color: var(--accent);
    font-family: "Noto Sans Mono", monospace;
    font-size: 8.2pt;
    font-weight: 700;
    min-width: 8mm;
}}

/* ---------- hoofdtekst ---------- */

main {{
    counter-reset: h2;
}}

main .lead {{
    color: #3e4345;
    font-size: 11.2pt;
    line-height: 1.6;
    margin-bottom: 6mm;
}}

main h2 {{
    counter-increment: h2;
    counter-reset: h3;
    margin: 8mm 0 3.5mm;
    padding-top: 1mm;
    font-size: 18pt;
    line-height: 1.15;
    letter-spacing: -0.015em;
    color: var(--accent-dark);
    border-top: 0.35mm solid var(--line);
    break-after: avoid;
}}

main h2::before {{
    content: counter(h2, decimal-leading-zero);
    display: inline-block;
    margin-right: 3mm;
    color: var(--accent);
    font-family: "Noto Sans Mono", monospace;
    font-size: 10pt;
    font-weight: 700;
    vertical-align: 0.35em;
}}

main h2:first-of-type {{
    margin-top: 4mm;
}}

main h2#sessie-en-systeem {{
    break-before: page;
}}

main h3 {{
    counter-increment: h3;
    margin: 7mm 0 2.5mm;
    font-size: 11.6pt;
    line-height: 1.25;
    color: #243033;
    break-after: avoid;
}}

main h3::before {{
    content: counter(h2) "." counter(h3);
    margin-right: 2.4mm;
    color: var(--accent);
    font-family: "Noto Sans Mono", monospace;
    font-size: 8.3pt;
    font-weight: 700;
}}

table {{
    width: 100%;
    margin: 2.5mm 0 4mm;
    border-collapse: collapse;
    font-size: 8.8pt;
    line-height: 1.42;
    break-inside: auto;
}}

table.keep {{
    break-inside: avoid;
}}

thead {{
    display: table-header-group;
}}

tr {{
    break-inside: avoid;
}}

th {{
    text-align: left;
    padding: 1.7mm 2.4mm;
    color: #f7f3ea;
    background: #2b3537;
    font-size: 7.7pt;
    font-weight: 600;
    letter-spacing: 0.04em;
    text-transform: uppercase;
}}

td {{
    padding: 1.65mm 2.4mm;
    border-bottom: 0.22mm solid var(--line);
    vertical-align: top;
}}

tbody tr:nth-child(even) td {{
    background: #f7f5ef;
}}

td:first-child {{
    font-weight: 500;
}}

blockquote {{
    margin: 4mm 0 5mm;
    padding: 3.2mm 4mm 3.2mm 4.5mm;
    background: var(--accent-soft);
    border-left: 1.2mm solid var(--accent);
    color: #2b3a3b;
    font-size: 9.1pt;
}}

blockquote p {{
    margin: 0;
}}

ul, ol {{
    margin: 0 0 4mm;
    padding-left: 5.5mm;
}}

li {{
    margin-bottom: 1.4mm;
}}

hr {{
    border: 0;
    border-top: 0.3mm solid var(--line);
    margin: 8mm 0 4mm;
}}

pre {{
    margin: 3mm 0 5mm;
    padding: 3.5mm 4mm;
    background: #23282a;
    color: #e9e4da;
    border-radius: 2mm;
    font-size: 8.1pt;
    line-height: 1.55;
    overflow: hidden;
    break-inside: avoid;
}}

pre code {{
    background: transparent;
    padding: 0;
    color: inherit;
    font-size: inherit;
}}

main > p:last-child em,
main > p:last-child {{
    color: var(--muted);
}}

@media print {{
    a {{
        color: var(--accent-dark);
    }}
}}
</style>
</head>
<body>

<section class="cover">
    <div class="cover-top">
        <span class="brand">Qtile · 0.34</span>
        <span>Cheat sheet · X11</span>
    </div>

    <div>
        <h1>Sneltoetsen<br><span>&amp; begrippen</span></h1>
        <p class="cover-sub">Een praktische handleiding voor deze qtile-desktop:
        alle toetsen, muisacties en balkkliks, plus de taal van de configuratie.</p>
        <div class="cover-rule"></div>
    </div>

    <div class="cover-bottom">
        <div class="cover-keys">
            <kbd>Super</kbd> + <kbd>Return</kbd> terminal &nbsp;·&nbsp;
            <kbd>Super</kbd> + <kbd>D</kbd> launcher &nbsp;·&nbsp;
            <kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>R</kbd> herladen
        </div>
        <div class="cover-meta">
            <div><span>Modifier</span><strong>Super (mod4)</strong></div>
            <div><span>Configuratie</span><strong>~/.config/qtile/config.py</strong></div>
            <div><span>Bijgewerkt</span><strong>{date_nl}</strong></div>
        </div>
    </div>
</section>

<section class="toc-page">
    <h2 class="toc-title">Inhoud</h2>
    <ul class="toc">
        {toc}
    </ul>
</section>

<main>
{body}
</main>

</body>
</html>
"""

dst.write_text(
    template.format(date_nl=date_nl, toc=toc, body=body),
    encoding="utf-8",
)
PY

"$CHROME" \
    --headless=new \
    --disable-gpu \
    --no-sandbox \
    --disable-dev-shm-usage \
    --no-pdf-header-footer \
    --run-all-compositor-stages-before-draw \
    --virtual-time-budget=5000 \
    --user-data-dir="$BUILD/chrome-profile" \
    --print-to-pdf="$PDF" \
    "file://$HTML" >/dev/null 2>&1

if [[ ! -s "$PDF" ]]; then
    echo "Fout: Chrome heeft geen pdf aangemaakt." >&2
    exit 1
fi

echo "PDF gemaakt: $PDF"
if command -v pdfinfo >/dev/null 2>&1; then
    echo "Pagina's: $(pdfinfo "$PDF" | awk '/^Pages:/ {print $2}')"
fi
