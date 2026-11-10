# Folded A6 Year Calendar

A printable year calendar that fits in a pocket. One A4 PDF per year, printed
double-sided and folded twice, becomes an A6 leaflet: 27 pages for 2026, each
showing two consecutive weeks with room to write.

The calendar is **English-only**, marks the four moon phases (new, first
quarter, full, last quarter) and the monastery event days, and is generated
with **Typst only** — no Python, pdfjam or pdftk.

## Build

Requirements:

- Typst 0.15.1
- the **Alegreya** and **Alegreya Sans** fonts installed (check with `typst fonts`)
- `poppler-utils` (`pdfinfo`, `pdftotext`, `pdfimages`) for the page count and
  the verification script

```sh
make notebook-planner YEAR=2026          # or: ./notebook-planner-build.sh 2026
```

Output: `dist/notebook-planner/notebook-planner-2026-two-weeks.pdf`. Years 2026–2030 have data.

Other targets:

```sh
make notebook-planner-watch YEAR=2026             # rebuild on every change
make notebook-planner-verify YEAR=2026            # acceptance checks, one pass/fail line each
make notebook-planner-proof                # fold-proof PDF: dist/notebook-planner/notebook-planner-proof.pdf
make notebook-planner-clean               # remove dist/notebook-planner/
```

The first `make notebook-planner-proof` print is the artefact for checking the imposition: the
panels carry only a large page number and an up arrow, so you can fold one
sheet and confirm the pages read 1 → 8 in order.

## Print

- A4, portrait.
- **Double-sided, flip on long edge.**
- **100 % / actual size** — no "fit to page", no borderless scaling needed.
- Plain paper is fine; a slightly heavier stock folds better.

## Fold

1. With page 1 face up, fold the sheet in half along the **vertical** centre
   line (the line between the two A6 columns).
2. Fold it in half again along the **horizontal** centre line, so the leaflet
   closes with page 1 on the front.
3. To read: open the first fold to see page 2; open fully to see pages 3 and 4.
4. Turn the sheet over and refold it the other way (same creases, opposite
   direction) to reach pages 5 → 8 in the same order.

Every panel keeps a 5 mm inset from its edges, so text and rules stay clear of
the folds and of the printer's non-printable margin.

## The imposition in one paragraph

Each A4 side carries four A6 panels in a 2 × 2 grid: bottom-right,
top-right, top-left, bottom-left in reading order. Because the two folds
reverse the orientation of the top and right panels, those panels are printed
rotated by 180°, so they come out upright once folded. Pages 1–4 sit on the
first A4 side (1 bottom-right, 2 top-right, 3 top-left, 4 bottom-left)
and pages 5–8 on the next side in the same positions; every side uses the same
layout, and turning the sheet over and refolding puts page 5 face up. PDF pages are
emitted in page order, four panels per side. With 27 pages for 2026
the last sheet side has three filled panels and one blank slot; that slot is
deliberate, so the final sheet is complete.

## Adding a year

Drop a CSV in the same format as the existing ones into `data/`, named
`data/events-<year>.csv`, then rebuild:

```sh
cp /path/to/events-2031.csv data/events-2031.csv
make notebook-planner YEAR=2031
```

No code change is needed. The CSV is semicolon-delimited with the header

```
date;day_text;footnote;label;phase;season;season_number;season_total;days
```

`date` is `YYYY-MM-DD`; `footnote` holds an event macro (see
`FOOTNOTE_TEXT_EN` in `lib.typ`) and `day_text` a moon macro (`\FullMoon`,
`\NewMoon`, `\FirstQuarter`, `\LastQuarter`). `notebook-planner-build.sh` lists the available
years and refuses to build a year without a data file.

## Repository layout

| path | purpose |
|---|---|
| `notebook-planner.typ` | the document: panel renderer, imposition, proof mode |
| `lib.typ` | colours, fonts, English tables, CSV loading, week/page model |
| `data/events-<year>.csv` | moon phases and event days per year |
| `assets/moons/*.png` | the four moon glyphs |
| `notebook-planner-probe.typ` | plain-text dump of the parsed model, used by the verify script |
| `notebook-planner-build.sh`, `notebook-planner-verify.sh`, `Makefile` | build, convenience targets, checks |
| `CLAUDE.md` (repo root) | notes for contributors: data model, imposition, pitfalls |
