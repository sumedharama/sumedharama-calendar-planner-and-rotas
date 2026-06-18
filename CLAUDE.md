# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A single-file [Typst](https://typst.app) document (`wall-planner.typ`) that generates a printable Buddhist wall-planner calendar for the Sumedhārāma monastery. It reproduces a legacy Excel/Google-Sheets layout: a three-month horizontal day grid (months stacked vertically) with moon phases, uposatha observance notes, and event labels. Month names are Portuguese; weekday headings are single-/two-letter English.

For a given year it emits **8 A4-landscape pages** — one quarter per pair of pages, each quarter split into a left and a right half meant to be printed and butted together side by side (page 1/2 = Jan-Feb-Mar left/right, 3/4 = Apr-May-Jun, etc.).

## Build

```sh
make                                              # compiles year 2026 -> wall-planner.pdf
typst compile --input year=2027 wall-planner.typ wall-planner.pdf
```

The year is read from `sys.inputs.year` (default 2026, see top of `wall-planner.typ`). Any year passed must have a matching `data/events-<year>.csv` (2026–2030 are present).

Render a single page to PNG for visual inspection (the normal way to verify layout changes):

```sh
typst compile --format png --pages 1 --ppi 150 wall-planner.typ /tmp/wp-{p}.png
```

Fonts **Alegreya** and **Alegreya Sans** must be installed (Alegreya lives in `~/.fonts`). Check with `typst fonts` — do **not** redirect its stderr to `/dev/null`, the font list prints there.

## Data model

`data/events-<year>.csv` is semicolon-delimited with header columns:
`date;day_text;footnote;label;phase;season;season_number;season_total;days`

`load_events()` builds a lookup keyed `"<month>-<day>"` -> `(kind, note, foot)`:
- **`day_text`** holds a LaTeX-style moon macro (`\FullMoon`, `\NewMoon`, `\FirstQuarter`, `\LastQuarter`) mapped via `MOON_KIND` to an asset name. When present, the moon image replaces the day number.
- **`footnote`** holds a LaTeX macro (e.g. `\xAsalhaPuja`) resolved to Portuguese display text via the `FOOTNOTE_TEXT` dict; rendered as a bordered event box. Multiple rows for the same date accumulate into the `foot` list.
- For **full/new** moons, the uposatha season note (e.g. `15d G 10/10`) is composed from `days`, `season` (via `SEASON_TEXT`), `season_number`/`season_total`. A `days` of `0`/empty suppresses it.

The CSV values were originally LaTeX macros; their canonical expansions live in `data/text-portuguese.tex`. The dicts at the top of `wall-planner.typ` (`FOOTNOTE_TEXT`, `MOON_KIND`, `SEASON_TEXT`, `MONTHS_PT`, `WEEKDAY_LETTERS`) are the in-Typst port of that — keep them in sync if the CSVs change.

## Layout architecture

- **`plan_group(year, months)`** picks the grid's starting weekday for a 3-month group: it tries each month's own 1st-of-month weekday as the candidate start and chooses the one minimising total grid width. Returns the start weekday, total column count, and each month's column offset. This is why the leftmost day column isn't always Monday.
- **`render_page(year, months, side, events)`** builds one A4 page as a single Typst `table`. Columns: an optional `LABEL_W` rotated-month-name column (left page only) plus the day columns for that half (`L` columns left, `R` right, sharing one pitch derived from the left page). Rows: weekday header strip, three 1fr month rows, weekday footer strip.
- Cell builders: `weekday_cell`, `month_label`, `day_cell`, `empty_cell` (off-month slate cells).

### Continuous-navy technique (important, non-obvious)

The blue header/footer strips and the left month-label column must read as one continuous field, while gold rules appear **only between day cells**. This is achieved by:
1. The table has `stroke: none`; only `day_cell`/`empty_cell` carry the gold rule (`DAY_STROKE`).
2. The navy regions are painted as **continuous `rect`s placed *behind* the table** (`place(...)` calls in `render_page`). The cream/white rasterisation seam between adjacent navy cell fills then shows the navy rectangle, not the page background.

Do **not** try to hide the seams with cell strokes — earlier attempts (per-side navy strokes, a navy global rule) caused navy nubs to protrude into the day grid at corners. The behind-the-table rectangles are the working solution because they involve no strokes at all.

Tunables (page margins, label width, header height, font sizes, moon size, theme colours) are the constants block near the top of `wall-planner.typ`.

## Notes

- `legacy-reference/` (source screenshots, the original `.xlsx`, the Google-Sheets PDF) and `*.pdf` output are gitignored.
- `prompts.org` records the design briefs that produced this layout.
