# PRD — Folded A6 Year Calendar (A4 n-up, Typst)

- **Feature slug:** `folded-a6-calendar`
- **Date:** 2026-11-10
- **Status:** Approved — open questions resolved, ready for task breakdown

---

## 1. Introduction / Overview

We want a printable year calendar that fits in a pocket. For a given year, the tool
produces a PDF of A4 sheets. Each A4 sheet carries **four A6 pages** (2 × 2) on each
side. The sheet is folded twice — once along the vertical middle and once along the
horizontal middle — so that the sheet becomes an A6 leaflet whose four panels are the
four pages. Printing both sides of the sheet gives **eight A6 pages per sheet**, each
panel showing **two consecutive weeks**.

The calendar is meant to be **written in**: after the date label, the rest of each day
cell is blank paper for handwriting appointments.

Two panels on every sheet side are printed **rotated by 180°**, because the folds
reverse their orientation. Getting this imposition right is the core of the feature.

The document is generated with **Typst only** (no Python, no pdfjam, no pdftk). This was
verified experimentally: Typst can place four fixed-size `box`es of 105 × 148.5 mm on a
210 × 297 mm page, rotate selected ones with `rotate(180deg, …)`, and clip content that
would overflow. See §7.1.

**How the leaflet is read (confirmed with the user).** The sheet is a leaflet, not a
bound book. Starting folded, page 1 is face up. Unfolding once reveals page 2; unfolding
completely reveals pages 3 and 4. To reach the back, the sheet is **unfolded and folded
again the other way**, which puts page 5 face up, then 6, 7 and 8 in the same way. This
is why pages 1–4 all sit on one side of the sheet and 5–8 on the other (see FR-21).

### Why Typst only

Typst keeps the whole build in one place, has no external dependencies beyond the
compiler, and the existing monastery projects already use it. A separate Python
imposition step would add a second toolchain for no gain, since the imposition is only
a matter of four `place()` calls per sheet side.

---

## 2. Goals

1. **G1 — Produce a foldable year calendar.** For a given year, emit an A4 PDF covering
   1 January to 31 December that, when printed double-sided and folded twice, yields A6
   pages in correct reading order.
2. **G2 — Two weeks per A6 page.** Each panel shows two consecutive weeks as two
   columns of seven day rows (the last page of the year may hold a single week).
3. **G3 — Moon phases.** Every new / first-quarter / full / last-quarter day is marked
   with the moon glyph reused from the Sumedhārāma projects, following the date.
4. **G4 — Reuse existing data and styling.** Reuse the `events-<year>.csv` data, the
   moon artwork and the colour/font scheme (`lib.typ`) from
   `sumedharama-calendar-planner-and-rotas`.
5. **G5 — Writable.** Each day row leaves the majority of its area blank for handwriting.
6. **G6 — One command.** `./build.sh 2026` (or `make calendar YEAR=2026`) produces
   `dist/calendar-2026.pdf` with no manual steps.
7. **G7 — Verifiable imposition.** A separate *fold proof* document lets a human check
   the imposition by folding one printed sheet.

---

## 3. User Stories

- **US-1.** As the person printing the calendar, I want a single PDF per year so that I
  can send it to a print shop or print it at home with duplex on, without per-page
  manual ordering.
- **US-2.** As the person folding the sheets, I want each panel to be clearly a page, so
  that after two folds the calendar reads in date order without me having to think.
- **US-3.** As the calendar's user, I want to see two weeks at a glance with enough blank
  space to write in my appointments.
- **US-4.** As a practising Buddhist, I want the moon days (uposatha) marked so that I can
  see observance days without consulting another document.
- **US-5.** As the maintainer, I want the moon data and monastery events to come from the
  same CSV files as the other Sumedhārāma calendars, so the data is maintained in one
  place.
- **US-6.** As the maintainer, I want to add next year's data by dropping in one CSV file
  and re-running the build.

---

## 4. Functional Requirements

### 4.1 Year input and data

- **FR-1.** The document must read the year from `sys.inputs.at("year", …)`, so that
  `typst compile --input year=2027 calendar.typ` works. With no input, the current year
  is used.
- **FR-2.** The build must fail with a clear, non-zero-exit error message when
  `data/events-<year>.csv` does not exist, e.g.
  `No data file data/events-2025.csv — add it or choose a year in 2026–2030.`
- **FR-3.** The repository must be **self-contained**: copy from
  `sumedharama-calendar-planner-and-rotas`:
  - `data/events-2026.csv` … `data/events-2030.csv`
  - `assets/moons/{new,first,full,last}.png`
  - `lib.typ` (adapted: see FR-4)
  No build step may read files from outside this repository.
- **FR-4.** Because this calendar is **all English** (see FR-24), add an English event
  name table to `lib.typ` (e.g. `FOOTNOTE_TEXT_EN`) covering every footnote macro used
  in the CSVs: `\xAjahnChahMemorialDay`, `\xAjahnChahBirthDay`, `\xThaiNewYear`,
  `\xFirstDayOfVassa`, `\xLastDayOfVassa`, `\xMaghaPuja`, `\xVesakhaPuja`,
  `\xAsalhaPuja`, `\xPavarana`. Suggested values: *Ajahn Chah Memorial Day*,
  *Ajahn Chah's Birthday*, *Thai New Year (Songkran)*, *First Day of Vassa*,
  *Last Day of Vassa*, *Māgha Pūjā*, *Vesākha Pūjā*, *Āsāḷhā Pūjā*, *Pavāraṇā*.
- **FR-5.** Moon phases must be derived exactly as in `morning-evening-puja.typ`:
  from the CSV `day_text` column via `MOON_KIND` (`\FullMoon`, `\NewMoon`,
  `\FirstQuarter`, `\LastQuarter`), keyed `"<month>-<day>"`. All four phases are marked
  (not only full/new).

### 4.2 Week and page sequencing

- **FR-6.** Weeks are **Monday-start**, seven days each.
- **FR-7.** The calendar must **cover the whole year**: it starts with the week that
  contains 1 January and ends with the week that contains 31 December. Dates from the
  neighbouring years that fall inside those weeks are shown normally (FR-11).
  For 2026: Mon 2025-12-29 → Sun 2027-01-03 = **53 weeks**. All years 2026–2030 need 53
  weeks (only a common year starting on a Monday needs 52).
- **FR-8.** Weeks are grouped in pairs, in order: page 1 = weeks 1–2, page 2 = weeks
  3–4, … For 2026 that gives **27 pages**, the last page holding only week 53 in its left
  column (right column blank). Left column = first week of the pair, right column = second
  week.
- **FR-9.** A6 pages are assigned to sheet panels in **reading order per side**:
  `bottom-right → top-right → top-left → bottom-left`, four per side, eight per sheet.
  For sheet *k* (0-based), base = 8k (positions as seen when viewing that side of the
  sheet):
  | position | page |
  |---|---|
  | bottom-right | 8k + 1 |
  | top-right | 8k + 2 |
  | top-left | 8k + 3 |
  | bottom-left | 8k + 4 |
  | bottom-right (back) | 8k + 5 |
  | top-right (back) | 8k + 6 |
  | top-left (back) | 8k + 7 |
  | bottom-left (back) | 8k + 8 |

  The back side uses the same slot pattern as the front; the pages simply continue
  5–8. This was confirmed by the physical fold test.
- **FR-10.** Panel slots beyond the last page are **left blank** (white, no rules) —
  this is deliberate, so the last sheet stays complete. For 2026 that is exactly **1 empty
  slot** (27 pages in 28 slots): the bottom-left panel of the last sheet side, i.e. the last
  slot in reading order. Any sheet side with no content at all is not emitted; any
  partially filled side is emitted.
- **FR-11.** Dates that fall outside the year but inside a displayed week (e.g.
  2027-01-01 in the last week) are rendered normally, with their own month
  abbreviation. The year is not printed inside day cells.

### 4.3 A6 panel content

- **FR-12.** Each panel is exactly **105 × 148.5 mm**. Inside a uniform **5 mm inset**
  (FR-17) the content area is **95 × 138.5 mm**, split into **two day columns of 47.5 mm**
  and **seven rows of 19.786 mm** (138.5 / 7).
- **FR-13.** Each day row shows, at the top-left, on one line:
  `<Mon> <day> <Www>` — three-letter English month, day number, three-letter English
  weekday, e.g. `Nov 9 Mon` (`Nov 10 Tue`, `Jan 5 Mon`). Font: Alegreya Sans, 7.5 pt,
  navy.
- **FR-14.** On a moon day the **moon glyph follows the date** (image, 4 mm — smaller than the
  5 mm used in the Sumedhārāma rotas, to suit the A6 panel), keeping the day number, e.g. `Nov 9 Mon [🌕]`. The
  glyph is the existing circular-clipped PNG via `moon(kind, size: …)` from `lib.typ`. It
  sits in a box as tall as the date text and is centred on the text line, so the date line
  and the event lines sit at the same place whether or not a moon is present. On full
  and new moons (uposatha) the short uposatha info follows the glyph, as in the wall
  planner: `Mar 3 Tue [🌕] 15d H 8/8` (days, season letter, number/total; 6.5 pt, navy).
- **FR-15.** If the day has one or more events from the CSV (`footnote` column), the
  English event names are printed under the date line, one per line, 5.5 pt, italic,
  navy. Long names may be truncated to fit the 47.5 mm column; they must never push the
  row beyond its 19.786 mm height.
- **FR-16.** A thin rule (0.4 pt, `GOLDLINE`) separates consecutive day rows, spanning
  the full column width. A thin vertical rule (same stroke) separates the two columns.
- **FR-17.** Each panel keeps a uniform **5 mm inset** from its edges. This one value
  covers both the **fold/trim zone** and the **non-printable margin** of ordinary
  printers, so the same PDF works when printed borderless or with a ~5 mm hardware
  margin. No text, rule or glyph may sit closer than 5 mm to a panel edge.
- **FR-18.** Panels are clipped: content that overflows a panel must be cut off rather
  than overlap the neighbouring panel (`box(…, clip: true)`).
- **FR-19.** There is **no header band, no footer band and no page number** on the
  panel. Maximum writing area is the priority.
- **FR-20.** As the only persistent identifier, print the **year** at 6.5 pt, letter-spaced
  gold, in the bottom-right corner of each panel (inside the 5 mm inset). Included on
  request; remove it if the printed proof feels crowded.

### 4.4 Page imposition (the core)

- **FR-21.** Every A4 page is **210 × 297 mm with zero margins** (`margin: 0mm`) and
  white fill. Each side places exactly four panels, filling the sheet edge to edge.
  **Every side uses the same layout** (for A4 side *s*, 0-based, base = 4s):

  ```
  ┌───────────────────────┬───────────────────────┐
  │  page 3               │  page 2               │
  │  rotated 180°         │  rotated 180°         │
  ├───────────────────────┼───────────────────────┤
  │  page 4               │  page 1               │
  │  upright              │  upright              │
  └───────────────────────┴───────────────────────┘
  ```

  | position | page | rotation |
  |---|---|---|
  | top-left | 4s + 3 | 180° |
  | top-right | 4s + 2 | 180° |
  | bottom-left | 4s + 4 | 0° |
  | bottom-right | 4s + 1 | 0° |

  There is no front/back distinction: the sheet is unfolded and re-oriented by hand when
  turning it over, so pages simply continue (1–4 on the first side, 5–8 on the next).
- **FR-22.** PDF pages are emitted side by side in page order, each advancing the base
  by four: PDF p. 1 = pages 1–4, p. 2 = pages 5–8, p. 3 = pages 9–12, … The last side
  may be partially filled (7 sides for 27 pages; FR-10).
- **FR-23.** If the physical fold test (FR-30) shows that a panel is out of order, the fix
  must be localised to the imposition table in this document and to one constant in
  `calendar.typ` — do not restructure the renderer.

### 4.5 Text, language, typography

- **FR-24.** All text is **English**: month abbreviations, weekday abbreviations, event
  names. Three-letter forms: `Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec` and
  `Mon Tue Wed Thu Fri Sat Sun`.
- **FR-25.** Typography and colours come from `lib.typ`: Alegreya (serif) and Alegreya
  Sans; navy `#1f3a5f` for text, gold `#c2972f` / `#b08a36` for accents and rules.
- **FR-26.** Saturday and Sunday rows are tinted with a very light warm tint (`#faf6ec`)
  to aid scanning. The tint must not change the cell's usable writing area. *(Included
  on request; review on the printed proof — see OQ-3.)*

### 4.6 Build, output and verification

- **FR-27.** The build produces `dist/calendar-<year>.pdf` and prints the page count.
- **FR-28.** `build.sh <year>` validates the year against available CSVs and creates
  `dist/` if needed.
- **FR-29.** A `Makefile` provides: `make calendar YEAR=2026`, `make watch YEAR=2026`,
  `make proof`, `make clean`.
- **FR-30.** `make proof` / the `--input proof=1` flag produces a **fold-proof PDF**: the
  same imposition, but each panel contains only a huge page number plus arrows showing
  which way is "up". This is the artefact used to confirm FR-21 by hand.
- **FR-31.** PDF metadata: title `Calendar <year>` and author `Sumedhārāma` (or the
  project name if it is generic).

---

## 5. Non-Goals (Out of Scope)

- **NG-1.** No Portuguese or bilingual variant. English only for now (a future `lang`
  input could be added, but is not part of this feature).
- **NG-2.** No uposatha season notes (`15d G 8/10`) inside day cells — prose and labels
  only, per the chosen layout.
- **NG-3.** No week numbers, no ISO week labels, no month-view grids, no "notes" box.
- **NG-4.** No binding, glueing or stitching: the object is a folded leaflet, not a
  sewn book.
- **NG-5.** No crop marks, registration marks or bleed. Panels fill the sheet exactly.
- **NG-6.** No Python, pdfjam, pdftk or other post-processing.
- **NG-7.** No support for years without a CSV data file (build must fail loudly, FR-2).
- **NG-8.** No web/GUI front end; command line only.
- **NG-9.** No guarantee about printer hardware; the user prints at 100 % / "actual size".
  The 5 mm panel inset (FR-17) absorbs the usual non-printable margin, so no scaling is
  needed.

---

## 6. Design Considerations

### 6.1 Panel anatomy

```
┌────────────────────────────────────────────────────┐  ← 5 mm inset on all four edges
│  ┌──────────────────────┬──────────────────────┐   │
│  │ Nov 9  Mon           │ Nov 16 Mon           │   │  ← date line, 7.5 pt
│  │                      │                      │   │
│  │                      │                      │   │
│  │ ──────────────────── ┼ ──────────────────── │   │  ← 0.4 pt rule
│  │ Nov 10 Tue           │ Nov 17 Tue           │   │
│  │                      │                      │   │
│  │                      │                      │   │
│  │ ──────────────────── ┼ ──────────────────── │   │
│  │ …                    │ …                    │   │
│  │                      │                2026  │   │  ← 6.5 pt year mark
│  └──────────────────────┴──────────────────────┘   │
└────────────────────────────────────────────────────┘
        47.5 mm                 47.5 mm
```

- Content area 95 × 138.5 mm; row height 19.786 mm. The date line occupies the top
  ~5 mm, leaving ~14 mm of blank writing space per day.
- Panel inset 5 mm on all sides — one value serving both fold/trim safety and the
  non-printable margin of ordinary printers.
- Visual language deliberately matches `morning-evening-puja.typ`: Alegreya Sans day
  numbers, navy text, gold hairlines, cream/white writable background.

### 6.2 Sheet anatomy

```
 A4 portrait 210 × 297 mm, zero margins
 ┌──────────────────┬──────────────────┐
 │   TL (105×148.5) │   TR (105×148.5) │   fold line at y = 148.5
 ├──────────────────┼──────────────────┤
 │   BL             │   BR             │   fold line at x = 105
 └──────────────────┴──────────────────┘
```

The two fold lines are exactly the panel boundaries, so every panel edge is either a
fold or a trimmed edge. This is why the 5 mm inset (FR-17) matters: text at a panel edge
is either folded through, cut off, or lost to a printer's non-printable margin.

### 6.3 Typography scale

| element | font | size | style |
|---|---|---|---|
| month | Alegreya Sans | 7.5 pt | medium, navy |
| day number | Alegreya Sans | 7.5 pt | medium, navy |
| weekday | Alegreya Sans | 7.5 pt | regular, navy 70 % |
| moon glyph | PNG asset | 4 mm | circular clip |
| event label | Alegreya | 5.5 pt | italic, navy |
| year mark | Alegreya Sans | 6.5 pt | letterspaced 0.6 pt, gold |

---

## 7. Technical Considerations

### 7.1 Imposition: Typst alone (verified)

Verified with Typst 0.15.1: a page with `margin: 0mm`, four
`box(width: 105mm, height: 148.5mm, clip: true)` panels placed with
`place(top + left, dx: …, dy: …)` and `rotate(180deg, panel)` produces the intended
layout. Rotation pivots on the box centre, so a fixed-size box stays in its slot.

Rules the implementation must follow:

1. Build each panel as a **fixed-size box**, never as reflowable content.
2. Use `clip: true` on the panel so overflow can never bleed into a neighbour.
3. Place panels with `place(top + left, dx: col*105mm, dy: row*148.5mm)`; wrap rotated
   panels as `place(…, rotate(180deg, panel))`.
4. Keep `margin: 0mm` and no `stroke` on the page; adjacent panel borders are drawn
   inside the panels.

### 7.2 Repository layout

```
notebook-calendar/
├── calendar.typ           # the document (imposition + panel renderer)
├── lib.typ                # copied from the sibling project; + English event table
├── data/events-2026..2030.csv
├── assets/moons/{new,first,full,last}.png
├── build.sh
├── Makefile
├── dist/calendar-<year>.pdf   (gitignored)
└── tasks/
```

### 7.3 Week generation algorithm

```
weeks = []
start = Jan 1 of YEAR, moved back to the preceding Monday
d = start
while d <= Dec 31 of YEAR:
    weeks.push(days d .. d+6)
    d += 7 days
pages[i] = (weeks[2i], weeks[2i+1])          # i = 0 .. ceil(len(weeks)/2) - 1
```

The last page may have only one week; render it in the left column and leave the right
column blank. For 2026: start = 2025-12-29, 53 weeks, 27 pages.

Each day entry needs: `datetime`, month abbrev, weekday abbrev, day number,
`moon_kind` (or `none`), `events[]`.

### 7.4 Sheet/pagination algorithm

```
slides = []
for each side in 0 .. ceil(pages.len()/4)-1:
    sheet  = side / 2
    isBack = side % 2 == 1
    base   = sheet * 8
    slots  = isBack
      ? [ (TL, base+7, 180), (TR, base+8, 0),
          (BL, base+6, 180), (BR, base+5, 0) ]
      : [ (TL, base+4, 0),   (TR, base+3, 180),
          (BL, base+1, 0),   (BR, base+2, 180) ]
    emit one A4 page placing pages[p] in each slot (blank if p out of range)
```

`ceil(27/4) = 7` sides → 4 sheets, last sheet front only.

### 7.5 Data loading

Reuse from the sibling project's `lib.typ`:

- `event_rows(year)` — CSV reader (`;` delimiter).
- `MOON_KIND` — `day_text` macro → phase kind.
- `moon(kind, size:)` — the glyph.
- `days_in_month`, `is_leap`, `WEEKDAYS_EN`, `MONTHS_EN`.
- Add `FOOTNOTE_TEXT_EN` (FR-4) and a `MONTHS_ABBR_EN` / `WEEKDAYS_ABBR_EN` helper.

Build one dictionary keyed `"<month>-<day>"` → `(moon: kind|none, events: (…))` per
year, scanning CSVs once.

### 7.6 Known pitfalls

- **Exact-fit rounding.** 2 × 148.5 mm and 2 × 105 mm exactly fill the sheet. If a
  hairline seam appears between panels in raster output, extend each panel by 0.2 mm on
  its inner edges rather than adding page margin.
- **`clip: true` needs a fixed-size box.** Attach it to the panel box, not to inner
  blocks.
- **Typst markup `else` gotcha** (inherited from the sibling project): in markup mode,
  keep `} else {` on the same line; a newline before `else` is parsed as literal text.
- **Fonts.** Alegreya and Alegreya Sans must be installed (`typst fonts` lists them on
  stderr; do not redirect stderr to `/dev/null`).
- **Rotation and text layout.** Lay out the panel content normally (upright) and rotate
  the whole finished panel; never lay out rotated text.

### 7.7 Verification steps (must be done)

1. `typst compile --input year=2026 calendar.typ` → check `pdfinfo` reports 7 pages.
2. Render page 1 and page 2 at 100 ppi to PNG and compare panel numbers with FR-21.
3. Render a single panel at high ppi and check: two columns, 7 rows, rules, date lines,
   moon glyphs, event labels, nothing clipped.
4. `make proof`, print one sheet duplex, **unfold it, then refold it the other way**, and
   confirm the pages read 1→8 in order with none upside down.
5. Check 2026-11-09 (Mon, new moon in the CSV) shows `Nov [moon] Mon` on page 23
   (weeks 45–46).

---

## 8. Success Metrics

- **SM-1.** A full 2026 build yields 7 A4 pages containing 27 A6 pages (54 week slots,
  one blank) = 53 weeks = 371 day cells, of which the 365 days of 2026 are all present
  exactly once (plus the 6 edge days of 2025/2027 that complete the first and last weeks).
- **SM-2.** Every moon day in `data/events-2026.csv` (all four phases) has a glyph in the
  output; verified by counting glyphs vs CSV rows.
- **SM-3.** Physical fold test passes on the first print: pages read 1→8 in order, with no
  page upside down, both after unfolding and after refolding for the back (FR-21/FR-30).
- **SM-4.** Build time under 5 seconds for one year.
- **SM-5.** A new year can be added by copying one CSV file and changing one command-line
  argument — no code edits.
- **SM-6.** No text or rule crosses a panel boundary (visual check of all 7 pages).

---

## 9. Open Questions

**None blocking.** Every question raised during review is settled; the list is kept here
as a record of the decisions so they are not re-litigated during implementation. Anything
that changes after the first printed proof is a small, localised tweak (all of the
relevant values are constants, FR-23).

Resolved during PRD review:

- ~~OQ-1 — year coverage.~~ **Resolved:** the calendar starts with the week containing
  1 January and ends with the week containing 31 December (FR-7). 2026 therefore has 53
  weeks and 27 pages.
- ~~OQ-2 — fold/reading model.~~ **Resolved:** the leaflet is read by unfolding, then
  unfolded and refolded the other way to reach the back (page 5 face up, then 6, 7, 8).
  The imposition in FR-21 follows from this.
- ~~OQ-3 — year mark / OQ-5 weekend tint / OQ-7 event labels.~~ **Resolved:** all three
  are included for now (FR-20, FR-26, FR-15). Review them on the first printed proof and
  drop whichever makes the panel feel crowded.
- ~~OQ-4 — trailing blank panel.~~ **Resolved:** keep it. The last sheet stays complete
  and the leftover slot is plain white (FR-10).
- ~~OQ-6 — panel inset.~~ **Resolved:** a uniform **5 mm** inset on every panel edge,
  serving both fold/trim safety and printer margins (FR-17). Content area is therefore
  95 × 138.5 mm; rows are 19.786 mm and columns 47.5 mm (FR-12).
- ~~OQ-8 — moon glyph vs day number.~~ **Resolved (revised):** the glyph **follows** the date
  and the day number stays (FR-14).
