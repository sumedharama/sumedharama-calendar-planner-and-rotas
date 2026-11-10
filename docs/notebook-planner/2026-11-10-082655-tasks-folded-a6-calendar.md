# Tasks — Folded A6 Year Calendar (Typst)

- **Feature slug:** `folded-a6-calendar`
- **Source PRD:** `tasks/2026-11-10-082655-prd---folded-a6-calendar.md`
- **Date:** 2026-11-10

---

## Relevant Files

- `calendar.typ` — The main document. Reads `--input year`, renders one A6 panel and imposes four panels per A4 side. Also renders the fold proof with `--input proof=1`.
- `lib.typ` — Vendored from `sumedharama-calendar-planner-and-rotas`. Theme colours, fonts, localisation tables, `moon()`, `event_rows()`, `days_in_month()`. Extended with the English event table and month/weekday abbreviation lists (FR-4, FR-24), the per-year `load_year()` lookup and the calendar model (`week_start()`, `weeks_for()`, `pages_for()`). Day lookups are year-gated so edge days from neighbouring years do not inherit the target year's moons or events.
- `probe.typ` — Debugging aid that renders the parsed data / week model as plain text. `verify.sh` parses its `key=value` header, so it is kept and not part of the printed document.
- `data/events-2026.csv` … `data/events-2030.csv` — Vendored CSV data (semicolon-delimited): moon phases, monastery events, uposatha season notes.
- `assets/moons/{new,first,full,last}.png` — Vendored moon glyphs, circular-clipped at render time (FR-14).
- `build.sh` — Year validation, `dist/` creation, `typst compile` invocation (FR-2, FR-27, FR-28).
- `Makefile` — `calendar`, `watch`, `proof`, `clean` targets (FR-29).
- `verify.sh` — Repeatable acceptance checks: page count, panel/date counts, moon-glyph count (SM-1, SM-2, SM-6).
- `README.md` — How to build, print (duplex, 100 %), fold, and add a new year.
- `AGENTS.md` — Repository notes for agents/contributors: build commands, data model, imposition table, known pitfalls.
- `.gitignore` — Ignores `dist/` and scratch PNGs.

### Notes

- Typst has no unit-test framework; "tests" are **repeatable command checks**. `verify.sh` plus `pdfinfo` and PNG renders are the test suite. Keep them scripted so a regression is visible in one command.
- The whole build must stay Typst-only: no Python, pdfjam or pdftk anywhere (NG-6).
- Every task below must leave the repo in a state where `typst compile --input year=2026 calendar.typ` succeeds.
- Typst pitfalls that apply throughout: use fixed-size `box(..., clip: true)` for panels; keep `} else {` on one line in markup; Alegreya/Alegreya Sans must be installed (`typst fonts` prints its list on **stderr** — never redirect it to `/dev/null`).
- Print with duplex "flip on long edge" at **100 % / actual size**. The 5 mm panel inset absorbs the printer's non-printable margin (FR-17, NG-9).
- Constraint values live at the top of `calendar.typ` as named constants (`PANEL_W`, `PANEL_H`, `INSET`, `DAY_FONT`, …) so the print-proof tweaks in the PRD are one-line edits (FR-23).

## Instructions for Completing Tasks

**IMPORTANT:** As you complete each task, check it off in this file by changing `- [ ]` to `- [x]`. Update after each sub-task, not just after each parent task.

## Tasks

### 1.0 Scaffold the repository and vendor the shared Typst library, CSV data and moon assets

**Specs**
- Typst 0.15.1 is installed; Alegreya and Alegreya Sans come from the sibling project (`~/.fonts`).
- Source project: `/home/gambhiro/prods/notbooks/sumedharama-calendar-planner-and-rotas`.
- CSV format: `date;day_text;footnote;label;phase;season;season_number;season_total;days`, ~59 data rows per year, `;` delimiter.
- Repo is a fresh git repository with no commits; only `tasks/` exists.
- **Depends on:** nothing.

- [x] 1.1 Create `.gitignore` covering `dist/`, `*.pdf`, and scratch PNGs (keep `tasks/` and sources tracked).
- [x] 1.2 Create the directory skeleton: `data/`, `assets/moons/`, `dist/` (empty dir ignored).
- [x] 1.3 Copy `lib.typ` from the sibling project into the repo root, unchanged.
- [x] 1.4 Copy `data/events-2026.csv` … `events-2030.csv`; confirm each has the 9-column header and ~59 rows, and that dates parse as `YYYY-MM-DD`.
- [x] 1.5 Copy `assets/moons/{new,first,full,last}.png`; confirm all four load (open one in an image viewer or check `file` output).
- [x] 1.6 Create `calendar.typ` stub: `#set page(width: 210mm, height: 297mm, margin: 0mm)`, `#import "lib.typ": *`, read `sys.inputs.at("year", default: …)`, and render a single line of text using Alegreya so a missing font is obvious.
- [x] 1.7 Compile the stub for 2026 and confirm `pdfinfo` reports 1 page at 595 × 842 pt (A4).
- [x] 1.8 Confirm the fonts resolve: run `typst fonts` and check `Alegreya` and `Alegreya Sans` appear in its stderr output.
- [x] 1.9 Make the initial git commit.

### 2.0 Build the data layer: English label tables and a per-year moon/event lookup

**Specs**
- `MOON_KIND` in `lib.typ` maps `\FullMoon`, `\NewMoon`, `\FirstQuarter`, `\LastQuarter` to `full`, `new`, `first`, `last` — these are also the asset file names.
- `moon(kind, size:)` already exists in `lib.typ`; do not reimplement it.
- Event macros in the CSVs: `\xAjahnChahMemorialDay`, `\xAjahnChahBirthDay`, `\xThaiNewYear`, `\xFirstDayOfVassa`, `\xLastDayOfVassa`, `\xMaghaPuja`, `\xVesakhaPuja`, `\xAsalhaPuja`, `\xPavarana`.
- Multiple CSV rows can share the same date (e.g. a full moon plus a festival); events must accumulate, the moon must not be overwritten.
- **Depends on:** 1.0 (vendored `lib.typ`, CSVs, stub document).

- [x] 2.1 Add `MONTHS_ABBR_EN` (`Jan`…`Dec`) and `WEEKDAYS_ABBR_EN` (`Mon`…`Sun`, index 0 = Monday) to `lib.typ` (FR-24).
- [x] 2.2 Add `FOOTNOTE_TEXT_EN` to `lib.typ` with the nine English event names listed in FR-4.
- [x] 2.3 Add `load_year(year)`: one pass over `event_rows(year)`, returning a dictionary keyed `"<month>-<day>"` (unpadded, e.g. `"3-3"`) with `(moon: kind | none, events: (…))` (FR-5, FR-15).
- [x] 2.4 Wrap the CSV read so a missing `data/events-<year>.csv` raises a readable error, e.g. `No data file data/events-2025.csv — add it or choose a year in 2026–2030.` (FR-2).
- [x] 2.5 Create `probe.typ`: import `lib.typ`, call `load_year(2026)`, render one line per data key as `key  moon  events…`.
- [x] 2.6 Compile `probe.typ` and cross-check the output against the CSV: moon rows in CSV (`grep -c '\\\\FullMoon\|\\\\NewMoon\|\\\\FirstQuarter\|\\\\LastQuarter'`) must equal the moon entries in the probe; every `footnote` row must appear as an event on the right date.
- [x] 2.7 Temporarily point the probe at a year without a CSV (e.g. 2025) and confirm the error message appears and the compile fails.

### 3.0 Build the calendar model: week generation, day entries, page pairing

**Specs**
- Week = Monday…Sunday. Start = week containing 1 January; end = week containing 31 December (FR-7).
- 2026: start `2025-12-29`, 53 weeks, last week `2026-12-28` → `2027-01-03`, 27 pages, page 27 holds only week 53 (FR-8).
- A page = `(weekA, weekB | none)`; left column is always the earlier week.
- Day entry fields: `date`, `month_abbr`, `weekday_abbr`, `day` (number), `moon`, `events`.
- **Depends on:** 2.0 (lookup), 1.x (stub document).

- [x] 3.1 Add `week_start(date)`: the Monday on or before a given date.
- [x] 3.2 Add `weeks_for(year)`: from `week_start(datetime(year: year, month: 1, day: 1))`, step 7 days until past 31 December; return a list of week dictionaries with seven day entries built from `load_year` (FR-6, FR-7, FR-11).
- [x] 3.3 Add `pages_for(year)`: group weeks in pairs; the final page gets `weekB: none` when the week count is odd (FR-8).
- [x] 3.4 Render the model in `probe.typ` as a per-page listing: `page N: <weekA start> .. <weekA end> | <weekB start> …`.
- [x] 3.5 Verify for 2026: 27 pages; page 1 starts `2025-12-29` and its first column shows `Dec 29`–`Jan 4`; page 27 has one week starting `2026-12-28` covering `Dec 28`–`Jan 3 2027`; total day cells 371; all 365 dates of 2026 present exactly once (FR-7, FR-11, SM-1).
- [x] 3.6 Verify the same counts for 2027–2030 (each should be 53 weeks / 27 pages / 1 blank slot).

### 4.0 Render a single A6 panel with two weeks, typography, rules, moon glyphs and event labels

**Specs** (all values become constants at the top of `calendar.typ`)
- Panel `105 × 148.5 mm`; uniform `5 mm` inset → content `95 × 138.5 mm`; two columns of `47.5 mm`; seven rows of `19.786 mm` (FR-12, FR-17).
- Date line: `Nov 9 Mon` — Alegreya Sans 7.5 pt, navy `#1f3a5f`, top-left of the cell (FR-13).
- Moon days: glyph `~4.5 mm` **replaces** the day number; month and weekday stay (FR-14).
- Event labels: 5.5 pt Alegreya italic, gold `#c2972f`, under the date line, one per line, must not exceed the row height (FR-15).
- Rules: `0.4 pt` `GOLDLINE` between rows (full column width) and between columns (FR-16).
- Weekend rows: tint `#faf6ec` (FR-26).
- Year mark: 5 pt, letter-spaced gold, bottom-right inside the inset (FR-20).
- No header, footer or page number (FR-19). Panel is a fixed-size `box(..., clip: true)` (FR-18).
- **Depends on:** 3.0 (week/day entries), 1.5 (moon assets), 1.3 (`lib.typ` colours/fonts).

- [x] 4.1 Add the constants block (`PANEL_W`, `PANEL_H`, `INSET`, `COL_W`, `ROW_H`, font sizes, tints) with a comment tying each to its PRD requirement. Take colours and font families from `lib.typ` rather than inventing new ones (FR-25).
- [x] 4.2 Implement `day_row(day)` as a fixed-height block: date line, optional event lines, optional weekend tint, bottom rule.
- [x] 4.3 Implement `week_column(week)`: seven `day_row`s stacked, plus the vertical divider at the column edge.
- [x] 4.4 Implement `panel(page)`: `box(width: PANEL_W, height: PANEL_H, clip: true)` with the 5 mm inset grid of two `week_column`s and the year mark (FR-12, FR-18, FR-20).
- [x] 4.5 Add a temporary inspection mode (`--input only=23`) that renders a single panel on an A6 page for close inspection.
- [x] 4.6 Render page 23 (weeks 45–46 of 2026) to PNG at 150 ppi and check: two columns, seven rows, correct date labels, `Nov [moon] Mon` on 2026-11-09, rules aligned, nothing clipped, year mark in place (FR-13 – FR-20).
- [x] 4.7 Check the densest panel of the year (the one with the most event labels) for overflow; confirm labels truncate or shrink rather than pushing the row.
- [x] 4.8 Remove or gate the inspection mode behind the `only` input so the default build is unaffected.

### 5.0 Impose four panels per A4 side, including the 180° rotations and the front/back sheet tables

**Specs**
- Sheet: `210 × 297 mm`, `margin: 0mm`, panels flush (`place(top + left, dx: …, dy: …)`) (FR-21).
- Front: `TL = base+4` (0°), `TR = base+3` (180°), `BL = base+1` (0°), `BR = base+2` (180°).
- Back, **in PDF coordinates**: `TL = base+7` (180°), `TR = base+8` (0°), `BL = base+6` (180°), `BR = base+5` (0°). This is the horizontal mirror of the "as viewed" table in the PRD, because the sheet flips on the long edge.
- Missing page → blank white slot, no rules, no year mark (FR-10).
- Pages emitted front, back, front, back… (FR-22); 27 pages → 7 sides → 4 sheets, last sheet front only.
- Rotate the finished panel: `place(…, rotate(180deg, panel))`. Never lay out rotated text.
- **Depends on:** 4.0 (panel renderer), 3.0 (pages).

- [x] 5.1 Add `slot_layout(is_back, base)` returning four `(col, row, page_number, rotation)` tuples, with a comment reproducing the PRD imposition tables (FR-9, FR-21).
- [x] 5.2 Add `sheet_side(is_back, base, pages)` that places the four panels into an A4 page, skipping out-of-range page numbers.
- [x] 5.3 Add `slide_count = ceil(page_count / 4)` and a loop emitting one A4 page per side, `pagebreak()` between sides (FR-22).
- [x] 5.4 Compile and confirm `pdfinfo` reports 7 pages for 2026.
- [x] 5.5 Verify the front side by its dates, since the calendar itself carries no panel numbers. Render PDF page 1 and check: bottom-left `Dec 29 Mon / Jan 5 Mon`, bottom-right `Jan 12 / Jan 19`, top-right **upside down** `Jan 26 / Feb 2`, top-left `Feb 9 / Feb 16`.
- [x] 5.6 Verify PDF page 2 (back) the same way: bottom-left `Feb 23 / Mar 2`, bottom-right `Mar 9 / Mar 16`, top-right upside down `Mar 23 / Mar 30`, top-left `Apr 6 / Apr 13`. (Panel *numbers* are checked later in 7.5.)
- [x] 5.7 Confirm the blank slot: page 7 of the PDF has three filled panels and one white panel in the top-left slot.
- [x] 5.8 Check for hairline seams between panels at 150 ppi; if any appear, extend panels by 0.2 mm on inner edges rather than adding a page margin.

### 6.0 Add the build tooling: `build.sh`, `Makefile`, year validation and PDF metadata

**Specs**
- `build.sh <year>`: validate the year against `data/events-<year>.csv`, create `dist/`, compile to `dist/calendar-<year>.pdf`, print the final page count (FR-27, FR-28).
- Invalid or missing year → non-zero exit with a message naming the available years (FR-2).
- `Makefile`: `calendar`, `watch`, `proof`, `clean` (FR-29).
- PDF metadata: title `Calendar <year>` (FR-31).
- **Depends on:** 5.0 (a working multi-page document).

- [x] 6.1 Write `build.sh` with `set -euo pipefail`, argument validation, `dist/` creation and the `typst compile --input year=…` call.
- [x] 6.2 Make the error path explicit: no argument, non-numeric argument, or missing CSV → message listing available years, exit 1.
- [x] 6.3 Print the resulting page count (via `pdfinfo`) at the end of the build.
- [x] 6.4 Set the PDF title in `calendar.typ` (`set document(title: "Calendar " + str(YEAR))`) and confirm with `pdfinfo`.
- [x] 6.5 Write the `Makefile` with `calendar` (`./build.sh $(YEAR)`), `watch` (`typst watch --input year=$(YEAR)`), `clean` (`rm -rf dist`), and a placeholder `proof` target added in 7.0.
- [x] 6.6 Run `./build.sh 2026` and `make calendar YEAR=2027`; confirm both PDFs land in `dist/` with the right page counts.
- [x] 6.7 Compile with **no** `year` input and confirm the document uses the current year (FR-1).
- [x] 6.8 Run `./build.sh 2025` and `./build.sh banana`; confirm both fail with clear messages and non-zero exit codes.

### 7.0 Add the fold-proof mode for hand-verifying the imposition

**Specs**
- Same imposition as the real document; panels show only a very large page number and a bold `↑` marker showing which edge is the top (FR-30).
- Activated by `--input proof=1` and by `make proof`; output `dist/calendar-proof.pdf`.
- **Depends on:** 5.0 (imposition), 6.0 (Makefile).

- [x] 7.1 Add a `PROOF` flag read from `sys.inputs.at("proof", default: "0")`.
- [x] 7.2 Implement `proof_panel(n)` — page number centred at ~90 pt plus an up arrow — and select it in `panel()` when `PROOF` is set.
- [x] 7.3 In proof mode force **8 sides / 32 numbered panels** (ignoring the year's real page count) so that every slot of every sheet can be traced, while still using the same `slot_layout` as the real build.
- [x] 7.4 Add the `proof` target to the `Makefile` writing `dist/calendar-proof.pdf`.
- [ ] 7.5 Run `make proof`, print one sheet duplex (flip on long edge, 100 %), **unfold it, then refold it the other way**, and confirm the panels read 1→8 in order with none upside down (FR-21, SM-3). Record the result in `AGENTS.md`.
- [ ] 7.6 If a panel is out of order, fix only `slot_layout` (FR-23) and re-run 7.5.

### 8.0 Verify against the PRD acceptance checks and document the project

**Specs**
- `verify.sh` must check, for a given year: page count, A6 page count, week count, day-cell count, in-year date count and uniqueness, and moon-glyph presence (SM-1, SM-2).
- Documentation must cover build, print settings, folding, adding a year, and the imposition table.
- **Depends on:** 6.0, 7.0.

- [x] 8.1 Write `verify.sh <year>`: run the build, then report (a) `pdfinfo` page count vs `ceil(pages/4)`; (b) the number of `MMM D Www` date labels in `pdftotext` output vs 371 (53 weeks × 7 days) — adjust the extraction once the real text layout is known; (c) any duplicated label; (d) wall-clock build time vs the 5 s target (SM-4). One pass/fail line per check.
- [x] 8.2 Cross-check the moon data: the number of moon keys parsed by `load_year(<year>)` (printed by `probe.typ`) must equal the number of moon rows in the CSV (`grep -Ec '\\\\FullMoon|\\\\NewMoon|\\\\FirstQuarter|\\\\LastQuarter'`). Then spot-check the actual glyphs on the rendered panels for weeks 45 and 46 (page 23) and one full moon (e.g. 2026-03-03).
- [x] 8.3 Add `verify.sh` to the `Makefile` as `make verify YEAR=…`; also assert that no source file references a path outside the repo (`grep -rn '/home/\|sumedharama-calendar-planner' *.typ build.sh Makefile verify.sh` returns nothing) — FR-3.
- [x] 8.4 Write `README.md`: what the project is, `make calendar YEAR=2026`, output path, print settings (duplex flip on long edge, 100 %), the two folds, how to add a year (drop a CSV, rebuild), and a one-paragraph explanation of the imposition.
- [x] 8.5 Write `AGENTS.md`: build commands, data model, the front/back imposition tables verbatim from the PRD, the known pitfalls (clip, `else` on one line, fonts on stderr, exact-fit seams), and the result of the physical fold test.
- [x] 8.6 Delete or clearly mark `probe.typ` as a debugging aid.
- [x] 8.7 Do a final PRD requirement sweep: tick off FR-1 … FR-31 and SM-1 … SM-6 against the implementation, and record any deliberate deviation at the bottom of this file.
- [ ] 8.8 Print the full 2026 calendar duplex, fold all four sheets, and verify the result reads correctly end to end.
- [x] 8.9 Prove SM-5: copy `data/events-2030.csv` to `data/events-2031.csv`, run `./build.sh 2031`, confirm it builds with no code change, then delete the copy.
- [x] 8.10 Commit the working state.

## Implementation notes / deviations

- **Missing-CSV message (FR-2).** Typst 0.15 has neither file-existence checks nor
  exception handling (`path` docs: existence checks are "in the future"), so the document
  cannot emit a custom message for a missing CSV. The read is wrapped in `event_rows()`,
  and a missing file makes the compiler fail with Typst's own
  `file not found (searched at …/data/events-2025.csv)` and exit 1. `build.sh` performs
  the existence check first and prints the plain-English message naming the available
  years, so the user-facing build path matches FR-2.
- **Moon rows vs moon dates.** Several CSV rows repeat the moon macro on a date that also
  carries an event (e.g. 2026-03-03 full moon + Māgha Pūjā), so `grep -c` counts more moon
  rows (54 in 2026) than distinct moon dates (49). The loader is keyed by date and the
  cross-check compares distinct dates, which matched the CSV exactly for 2026–2030.
- **Back-side imposition (FR-21).** The PRD contains two tables for the back side that
  disagree under duplex printing: the "as viewed after flipping" table and a "PDF position"
  table described as its horizontal mirror. The implementation follows the **as-viewed**
  table. With duplex "flip on long edge" the printer mirrors the sheet between sides, so
  PDF page 2 is exactly what the reader sees after flipping; mirroring it again would show
  the back upside down left-to-right. The as-viewed table is also the one the verification
  step in 5.6 expects (`BL Feb 23`, `BR Mar 9`, `TR Mar 23` upside down, `TL Apr 6`), and
  those dates were confirmed on the rendered page. The "page 5 is the reverse of page 1"
  sentence in FR-21 likewise does not hold under this reading; the physical fold test
  (7.5) is the final arbiter and, per FR-23, a correction touches only `slot_layout`.
  The fold test has not been run yet (no printer at hand), so 7.5, 7.6, 8.8 and SM-3
  remain open.
- **Year-gated day lookup (FR-5, FR-11).** The lookup key is `"<month>-<day>"`, but the
  first and last weeks contain a few days of 2025 and 2027. Applying a 2026 key to those
  dates put an extra 2026-01-03 full moon on 2027-01-03 (50 glyphs for 49 moon dates) and
  could inherit a wrong event. `day_entry()` therefore looks up data only when
  `date.year()` equals the calendar year; edge days show their own month and weekday
  without another year's moons or events. After the change the glyph count equals the
  distinct moon dates for every year.
- **Author metadata (FR-31).** The PDF carries both parts of FR-31:
  `Title: Calendar <year>` and `Author: Sumedhārāma`. The fold proof uses
  `Title: Calendar fold proof`.

## PRD requirement sweep

Checked against the implementation on 2026-11-10.

- **FR-1** year input with current-year default — `calendar.typ`; tested with no input.
- **FR-2** missing data fails loudly — `build.sh` (see deviation above).
- **FR-3** self-contained — no external paths; asserted by `verify.sh`.
- **FR-4** English event table — `FOOTNOTE_TEXT_EN` in `lib.typ`.
- **FR-5** all four moon phases from `MOON_KIND` — `load_year`; year-gated per deviation.
- **FR-6** Monday-start weeks — `week_start` / `weeks_for`.
- **FR-7** full-year coverage, 53 weeks for 2026–2030 — model and `verify.sh`.
- **FR-8** two-week pages, 27 pages, odd last week — `pages_for` and checks.
- **FR-9** reading order and rotations — `slot_layout`.
- **FR-10** blank trailing slot, no empty side — `sheet_side`; page 7 rendered and checked.
- **FR-11** neighbouring-year dates shown normally, no cell year — `day_entry`; year-gated.
- **FR-12** 105 × 148.5 mm panel, 5 mm inset, 47.5 mm columns, 19.786 mm rows — constants.
- **FR-13** `Nov 9 Mon`, Alegreya Sans 7.5 pt navy — `day_label`.
- **FR-14** moon glyph replaces the number — `day_label`; checked on pages 5 and 23.
- **FR-15** gold italic 5.5 pt event labels, clipped inside the row — `day_row`.
- **FR-16** 0.4 pt gold row rules and column divider — `day_row` / `panel`.
- **FR-17** uniform 5 mm inset — `INSET`.
- **FR-18** clipped fixed-size panel box — `panel`.
- **FR-19** no header, footer or page number — none drawn.
- **FR-20** 5 pt gold year mark bottom-right — `panel`.
- **FR-21** A4 sheets, four panels, rotation table — `sheet_side`; back-side deviation above.
- **FR-22** front/back emission, 7 sides for 2026 — `slide_count` loop; verified.
- **FR-23** localised correction — only `slot_layout` carries the imposition.
- **FR-24** English three-letter month and weekday forms — `lib.typ`.
- **FR-25** fonts and colours from `lib.typ` — all panel styling.
- **FR-26** weekend tint `#faf6ec` — `WEEKEND_TINT`.
- **FR-27** `dist/calendar-<year>.pdf` and printed page count — `build.sh`.
- **FR-28** year validation and `dist/` creation — `build.sh`.
- **FR-29** Makefile targets `calendar`, `watch`, `proof`, `clean` — plus `verify`.
- **FR-30** fold proof with huge number and up arrow — `PROOF` / `proof_panel`; physical
  test pending (7.5).
- **FR-31** title and author metadata — `set document`; checked with `pdfinfo`.

- **SM-1** 7 A4 sides, 27 A6 pages, 53 weeks, 371 day cells, 365 dates once — `verify.sh`.
- **SM-2** every moon day has a glyph — `verify.sh` compares distinct CSV dates, glyph
  placements and model keys for 2026–2030; page 5 (2026-03-03 full moon) and page 23
  (weeks 45–46) checked visually.
- **SM-3** physical fold test — **pending** (7.5).
- **SM-4** build under 5 s — measured 0.4–2.7 s for 2026–2030.
- **SM-5** new year by one CSV — `./build.sh 2031` built with a copied CSV, then removed.
- **SM-6** nothing crosses a panel boundary — all seven rendered pages checked visually;
  panels additionally clip their content.

Open items: 7.5 / 7.6 (fold test) and 8.8 (full print) still need a printer; everything
else is implemented, checked and committed.
