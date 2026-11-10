# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A set of [Typst](https://typst.app) documents for the Sumedhārāma monastery, sharing helpers from `lib.typ` (theme colours, fonts, localisation tables, the `moon()` glyph and CSV loading — keep cross-document changes there):

- **`wall-planner.typ`** — a printable Buddhist wall-planner calendar (see below).
- **`moon-days.typ`** — a four-page "Moon Days" overview sheet (see *The moon-days sheet*).
- **`morning-evening-puja.typ`** — a four-page puja rota sheet (see *The morning/evening puja sheet*).
- **`pindapata.typ`** — a four-page A4 piṇḍapāta rota, same cut-out-strip format as the puja sheet but with a single writable column (see the file header).
- **`daily-schedule.typ`** — a single A5 noticeboard page with the daily timetable (no year; read the file header).
- **`notebook-planner.typ`** — a folded A6 pocket year calendar (see *The notebook planner*).

`wall-planner.typ` reproduces a legacy Excel/Google-Sheets layout: a three-month horizontal day grid (months stacked vertically) with moon phases, uposatha observance notes, and event labels. Month names are Portuguese; weekday headings are single-/two-letter English.

For a given year it emits **8 A4-landscape pages** — one quarter per pair of pages, each quarter split into a left and a right half meant to be printed and butted together side by side (page 1/2 = Jan-Feb-Mar left/right, 3/4 = Apr-May-Jun, etc.).

## Build

### Make targets

```sh
make                          # full release build: ./build.sh (needs typst, pdftk, poppler-utils)
make wall-planner             # typst watch, 2026 -> wall-planner.pdf (repo root, gitignored)
make moon-days                # typst watch, 2026 -> moon-days.pdf
make morning-evening-puja     # typst watch, 2026 -> morning-evening-puja.pdf
make pindapata                # typst watch, 2026 -> pindapata.pdf
make daily-schedule           # typst watch -> daily-schedule.pdf
make notebook-planner YEAR=2026   # + -one-week, -bw, -one-week-bw, -all, -watch, -proof, -verify, -clean
```

The five watch targets are for live editing one document (change the `--input year=` in the Makefile for another year). The `notebook-planner*` targets are described in *The notebook planner*.

**Bare `make` / `./build.sh [<from> <to>]`** (years default to the range of `data/events-<year>.csv`) wipes `dist/`, then builds:
- `dist/daily-schedule.pdf`;
- `dist/{wall-planner,moon-days,morning-evening-puja,pindapata}-<from>-<to>.pdf` — every year concatenated with pdftk;
- `dist/notebook-planner/notebook-planner-<year>-{two-weeks,one-week,two-weeks-bw,one-week-bw}.pdf`;
- `dist/sumedharama-calendars-<from>-<to>.pdf` — everything joined: daily schedule, the four range PDFs, then the notebook PDFs (311 pages for 2026–2030).

It aborts unless exactly 6 PDFs sit directly in `dist/`. Add a document to the build by extending `names` in `build.sh`, and update that count.

### Single document

```sh
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

The CSV values were originally LaTeX macros; their canonical expansions live in `data/text-portuguese.tex`. The dicts in `lib.typ` (`FOOTNOTE_TEXT`, `MOON_KIND`, `SEASON_TEXT`, `PHASE_INFO`, `MONTHS_PT`, `WEEKDAY_LETTERS`) are the in-Typst port of that — keep them in sync if the CSVs change.

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

## The moon-days sheet (`moon-days.typ`)

A standalone overview poster styled after `legacy-reference/Moon Days.png`. Emits **4 A5-portrait pages, one per quarter** of the year (page 1 = Jan-Mar, … page 4 = Oct-Dec). Build/inspect exactly like the wall planner:

```sh
typst compile moon-days.typ moon-days.pdf            # current year (sys.inputs.year, default today)
typst compile --input year=2027 moon-days.typ moon-days.pdf
typst compile --format png --ppi 150 moon-days.typ '/tmp/md-{p}.png'
```

Each page (layout mirrors `legacy-reference/Moon Days layout blocks.png`):
- the `assets/wheel-and-lotuses.png` crest, then a bilingual title (`Moon Days <year>` / `Dias da Lua <year>`) with the quarter's English month range underneath;
- a left **legend** column — the four phase moons (new / waxing / full / waning) with bilingual names, plus the reflection note;
- a right **moon-days table** — that quarter's phase days as `moon | date | – | "English / Portuguese"` rows. Data comes from `load_moon_days(year)` (lib.typ), which yields the four-phase days via `PHASE_INFO`.

`assets/moon-days-background.png` (opaque, ISO-A ratio) is the full-bleed gold page frame, set as the page `background`. **Fitting note:** A5 is narrower than the A4 reference, so weekday/month names are abbreviated to three letters and the table/legend widths and font sizes are tuned so the fullest quarter (13 rows) stays on one page — re-check page count (`pdfinfo`) after any size/spacing change, as small additions easily push a quarter onto a second page.

## The morning/evening puja sheet (`morning-evening-puja.typ`)

A noticeboard rota styled after `legacy-reference/2026-06-17_19-46 morning-evening pujas.png`. Emits **4 A4-portrait pages, one per quarter** (page 1 = Jan-Mar, … page 4 = Oct-Dec), each showing its three months side by side as self-contained strips (each repeats its own `Morning / Evening Puja` title + Portuguese month band) meant to be **cut out and pinned** individually. The three strips touch with **no column gutter**, so the shared edge is a single cut line between adjacent months. Build/inspect like the others:

```sh
typst compile morning-evening-puja.typ                       # current year (sys.inputs.year)
typst compile --input year=2027 morning-evening-puja.typ morning-evening-puja.pdf
typst compile --format png --ppi 140 morning-evening-puja.typ '/tmp/me-{p}.png'
```

Each month strip is one Typst `table` with columns `weekday · day · Manhã · Tarde` (the two blank `1fr` columns are the writable morning/evening roster areas, labelled by a sub-header row). Rows run day 1..end-of-month; **on moon days the phase icon replaces the day number** (`load_moons()` builds a `"month-day" -> kind` lookup from `day_text`/`MOON_KIND`, same source as the wall planner — so all four phases appear). Moon days get a cream cell fill and weekends a faint gold tint.

**Markup gotcha:** the day cell uses an inline `#if … {…} else {…}`. In Typst markup mode the `else` must stay on the **same line** as the preceding `}` — an `else` on a new line is parsed as literal text and the source tokens render into the cells. Keep them together.

## The notebook planner (`notebook-planner.typ`)

A folded A6 pocket year calendar (English-only), merged in from the former `notebook-calendar` project. Four A6 panels per A4 side, printed duplex and folded twice into an eight-page leaflet. Each day is one row: `Nov 9 Mon`, then the moon icon (which follows the date rather than replacing it) and, on full/new moons, the uposatha note (`15d H 8/8`). User-facing build/print/fold instructions: `docs/notebook-planner/README.md` (the original PRD/task list are alongside, historical).

```sh
make notebook-planner YEAR=2026            # dist/notebook-planner/notebook-planner-2026-two-weeks.pdf
make notebook-planner-one-week YEAR=2026   # one week per A6 panel
make notebook-planner-bw YEAR=2026         # high-contrast B/W (also notebook-planner-one-week-bw)
make notebook-planner-all                  # 4 PDFs for every year with data (YEAR=2026 for one)
make notebook-planner-verify YEAR=2026     # acceptance checks (needs poppler-utils)
make notebook-planner-proof                # numbered fold-proof PDF
```

Scripts: `notebook-planner-build.sh`, `notebook-planner-verify.sh`; `notebook-planner-probe.typ` dumps the parsed model as text for the verify script (keep its `key=value` header). Bare `make` (`build.sh`) wipes `dist/`, builds all documents, then all four notebook variants per year into `dist/notebook-planner/`, and finally joins everything (daily schedule, the per-document range PDFs, then the notebook PDFs) into `dist/sumedharama-calendars-<from>-<to>.pdf` with pdftk; it checks for exactly 6 PDFs directly in `dist/`. Typst inputs: `year`, `layout` (`two-weeks`|`one-week`), `theme` (`colour`|`bw`), `proof=1`, `only=<panel>`. Build is Typst plus shell only (no Python/pdfjam/pdftk for this target).

Shared with the other documents via `lib.typ` and `data/`: colours, fonts, `MOON_KIND`, `SEASON_TEXT`, `moon()`, `event_rows()`. Notebook-only additions in `lib.typ`: `FOOTNOTE_TEXT_EN` (English event labels — keep in sync with `FOOTNOTE_TEXT`), `MONTHS_ABBR_EN`/`WEEKDAYS_ABBR_EN`, `moon_bw()` (vector B/W moon), `load_year()` and the week/page model (`weeks_for`, `pages_for`).

Key points:
- `load_year(year)` → `"<month>-<day>"` (unpadded) → `(moon, events, note)`. Several CSV rows may share a date: events accumulate, moon is never overwritten. `day_entry()` gates on `date.year() == year` so spill-over days in the first/last week don't inherit the year's moons/events. Weeks are Monday-start, from the week of 1 Jan to the week of 31 Dec; two weeks per A6 page (2026: 53 weeks, 27 pages).
- Panels are `box(width: PANEL_W, height: PANEL_H, clip: true)` with absolutely placed fixed-height day rows; rotate the *finished* panel by 180° rather than laying out rotated text. 5 mm inset on every panel.
- Imposition (`slot_layout(base)`, `base = 4s`, same on every A4 side): top-left page 4s+3 rotated, top-right 4s+2 rotated, bottom-left 4s+4 upright, bottom-right 4s+1 upright. Pages past the last leave a blank slot. If a panel is out of order after a hand fold, fix only `slot_layout`; record the `make notebook-planner-proof` result (not yet recorded as run).
- Theme values are the `INK`/`ACCENT`/`RULE*`/`WEEKEND_TINT` lets at the top of `notebook-planner.typ` — use them, not `NAVY`/`GOLD`, in panel code.
- Pitfalls: `} else {` on one line in markup; four panels exactly fill 210×297 mm (extend inner edges 0.2 mm if a hairline seam appears); `pdftotext -layout` scrambles 180° panels, use `-raw`.
## Notes

- `legacy-reference/` (source screenshots, the original `.xlsx`, the Google-Sheets PDF) and `*.pdf` output are gitignored.
- `prompts.org` records the design briefs that produced this layout.
