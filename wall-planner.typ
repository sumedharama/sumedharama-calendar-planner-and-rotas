// ============================================================================
// Sumedhārāma Wall Planner Calendar
//
// Reproduces the three-month horizontal wall-planner (originally an Excel /
// Google Sheets layout) in Typst.
//
// For the chosen year it produces 8 A4-landscape pages, one quarter per pair of
// pages (left half / right half), meant to be printed and placed side by side:
//
//   Page 1/2  Jan Feb Mar   (left / right)
//   Page 3/4  Apr May Jun   (left / right)
//   Page 5/6  Jul Aug Sep   (left / right)
//   Page 7/8  Oct Nov Dec   (left / right)
//
// Set the year below.
// ============================================================================

// Override from the CLI with:  typst compile --input year=2027 wall-planner.typ
#let YEAR = int(sys.inputs.at("year", default: "2026"))

// Shared colours, fonts, localisation tables, the moon glyph and CSV loading.
#import "lib.typ": *

// ---------------------------------------------------------------------------
// Tunables (millimetres)
// ---------------------------------------------------------------------------
#let PAGE_MARGIN   = 6mm     // margin on every edge
#let LABEL_W       = 22mm    // width of the rotated month-name column (left page)
#let HEADER_H      = 8mm     // top / bottom weekday strip height
#let GRID_STROKE   = 0.5pt
#let DAY_FONT      = 15pt    // day-number size
#let WEEKDAY_FONT  = 11pt    // weekday letter size
#let FOOT_FONT     = 6.5pt   // event-label size
#let NOTE_FONT     = 6pt     // uposatha season-note size
#let MOON_SIZE     = 17pt

// ---------------------------------------------------------------------------
// Event data: build a lookup keyed "month-day" -> (kind, note, footnotes)
// ---------------------------------------------------------------------------
#let load_events(year) = {
  let events = (:)
  for row in event_rows(year) {
    let date = row.at("date", default: "")
    if date == "" { continue }
    let parts = date.split("-")
    let key = str(int(parts.at(1))) + "-" + str(int(parts.at(2)))
    let entry = events.at(key, default: (kind: none, note: "", foot: ()))
    let day_text = row.at("day_text", default: "")
    if day_text in MOON_KIND { entry.kind = MOON_KIND.at(day_text) }
    let foot = row.at("footnote", default: "")
    if foot != "" {
      let txt = FOOTNOTE_TEXT.at(foot, default: foot)
      entry.foot = entry.foot + (txt,)
    }
    // uposatha note for full / new moons, e.g. "15d G 8/10"
    let phase = row.at("phase", default: "")
    if phase == "full" or phase == "new" {
      let sname = SEASON_TEXT.at(row.at("season", default: ""), default: "")
      let days = row.at("days", default: "")
      if sname != "" and days != "" and days != "0" {
        entry.note = days + "d " + sname + " " + row.at("season_number") + "/" + row.at("season_total")
      }
    }
    events.insert(key, entry)
  }
  events
}

// ---------------------------------------------------------------------------
// Layout: choose the grid start weekday and total width for a 3-month group
// ---------------------------------------------------------------------------
#let plan_group(year, months) = {
  let info = months.map(m => (
    wd: first_weekday(year, m),
    nd: days_in_month(year, m),
  ))
  // candidate start weekdays: each month's own start weekday (offset 0 there)
  let best = none
  for cand in info.map(x => x.wd) {
    let width = calc.max(..info.map(x => calc.rem(x.wd - cand + 7, 7) + x.nd))
    if best == none or width < best.width or (width == best.width and cand < best.start) {
      best = (start: cand, width: width)
    }
  }
  let offsets = info.map(x => calc.rem(x.wd - best.start + 7, 7))
  (start: best.start, width: best.width, offsets: offsets,
   ndays: info.map(x => x.nd))
}

// ---------------------------------------------------------------------------
// Cell builders
// ---------------------------------------------------------------------------
// The navy cells carry no rule of their own. Continuous navy rectangles are
// painted behind the table (see render_page), so the cream rasterisation seam
// between two navy cell fills shows navy instead of cream — invisible, and with
// no strokes there are no corner nubs poking into the day grid.
#let weekday_cell(letter, pos) = table.cell(fill: NAVY)[
  #set align(center + horizon)
  #text(font: SANS, size: WEEKDAY_FONT, weight: "medium", fill: CREAM)[#letter]
]

// gold rule drawn only around day / off-month cells, so the rules appear
// between the days but never within the continuous navy regions
#let DAY_STROKE = GRID_STROKE + GOLDLINE

#let empty_cell = table.cell(fill: DISABLED, stroke: DAY_STROKE)[]

#let day_cell(d, entry) = table.cell(
  fill: if entry != none and entry.kind in ("full", "new") { CREAM } else { DAYBG },
  stroke: DAY_STROKE,
)[
  #set align(center + top)
  // uposatha full / new moon cells get a top + bottom background decoration;
  // placed out of flow so the day number / note / event box keep their position
  #if entry != none and entry.kind in ("full", "new") {
    place(top + center, dy: 0.3mm, image("assets/cell-top-decor-1.png", width: 98%))
    place(bottom + center, dy: -0.3mm, image("assets/cell-bottom-decor-1.png", width: 98%))
  }
  #pad(top: 2.0mm, x: 0.6mm)[
    // tight spacing between the number/moon, the season note and the event box
    #set par(spacing: 2.0mm)
    // day number, or the moon graphic in its place
    #if entry != none and entry.kind != none {
      moon(entry.kind, size: MOON_SIZE)
    } else {
      // box of the moon's height so the number sits centred on the moon line
      box(height: MOON_SIZE, align(horizon,
        text(font: DAYNUM_FONT, size: DAY_FONT, fill: NAVY)[#d]))
    }
    // uposatha season note under the full / new moon
    #if entry != none and entry.note != "" {
      set par(leading: 0.3em, spacing: 2.0mm, justify: false)
      text(font: SANS, size: NOTE_FONT, fill: NAVY)[#entry.note]
    }
    // event labels in a bordered box
    #if entry != none and entry.foot.len() > 0 {
      set par(leading: 0.3em, spacing: 2.0mm, justify: false)
      set align(center)
      for f in entry.foot {
        block(
          width: 100%, fill: EVENTBG, stroke: 0.6pt + GOLD, radius: 1.2pt,
          inset: (x: 1mm, y: 0.6mm), below: 0.8mm,
          text(font: SERIF, style: "italic", size: FOOT_FONT, fill: NAVY)[#f],
        )
      }
    }
  ]
]

// label cell with small abbreviation (top) + large rotated month name
#let month_label(name) = table.cell(fill: NAVY)[
  #set align(center + horizon)
  #grid(rows: (auto, 1fr), row-gutter: 2mm,
    pad(top: 1.5mm)[#text(font: SANS, size: 8.5pt, weight: "medium", fill: CREAM)[#name]],
    align(center + horizon)[#rotate(-90deg, reflow: true)[
      #text(font: MONTH_FONT, size: 24pt, fill: GOLD)[#name]
    ]]
  )
]

// ---------------------------------------------------------------------------
// Render one page (side = "left" or "right")
// ---------------------------------------------------------------------------
#let render_page(year, months, side, events) = {
  let g = plan_group(year, months)
  let C = g.width
  let L = calc.div-euclid(C, 2)          // columns on the left page
  let R = C - L

  // global day-column positions shown on this page (1-based)
  let cols = if side == "left" { range(1, L + 1) } else { range(L + 1, C + 1) }

  // day-column width: derived from the left page so both pages share the pitch
  let usable = 297mm - 2 * PAGE_MARGIN
  let day_w = (usable - LABEL_W) / L

  // table column tracks
  let tracks = ()
  if side == "left" { tracks.push(LABEL_W) }
  for _ in cols { tracks.push(day_w) }

  // weekday letter for a global position p (1-based)
  let wd_letter(p) = WEEKDAY_LETTERS.at(calc.rem(g.start + (p - 1), 7))

  // ---- assemble rows ----
  let header = ()
  if side == "left" {
    header.push(table.cell(fill: NAVY)[
      #set align(center + horizon)
      #text(font: SERIF, size: 14pt, weight: "bold", fill: GOLD)[#str(year)]
    ])
  }
  for p in cols { header.push(weekday_cell(wd_letter(p), "head")) }

  let footer = ()
  if side == "left" { footer.push(table.cell(fill: NAVY)[]) }
  for p in cols { footer.push(weekday_cell(wd_letter(p), "foot")) }

  // month rows
  let body = ()
  for i in range(3) {
    if side == "left" { body.push(month_label(MONTHS_PT.at(months.at(i) - 1))) }
    let off = g.offsets.at(i)
    let nd = g.ndays.at(i)
    let mnum = months.at(i)
    for p in cols {
      let d = p - off
      if d >= 1 and d <= nd {
        let entry = events.at(str(mnum) + "-" + str(d), default: none)
        body.push(day_cell(d, entry))
      } else {
        body.push(empty_cell)
      }
    }
  }

  set page(
    width: 297mm, height: 210mm,
    margin: PAGE_MARGIN,
    fill: NAVY,
  )

  // Continuous navy bands painted behind the table: the top / bottom weekday
  // strips and (left page) the month-label column. The seams between the navy
  // cells then reveal navy, not the page cream — so the blue reads continuous
  // without any rules that could protrude into the day grid.
  let total_w = tracks.sum()
  let total_h = 210mm - 2 * PAGE_MARGIN
  place(top + left, rect(width: total_w, height: HEADER_H, fill: NAVY))
  place(bottom + left, rect(width: total_w, height: HEADER_H, fill: NAVY))
  if side == "left" {
    place(top + left, rect(width: LABEL_W, height: total_h, fill: NAVY))
  }

  table(
    columns: tracks,
    rows: (HEADER_H, 1fr, 1fr, 1fr, HEADER_H),
    stroke: none,                 // only the day cells carry the gold rule
    inset: 0pt,
    ..header,
    ..body,
    ..footer,
  )
}

// ---------------------------------------------------------------------------
// Document
// ---------------------------------------------------------------------------
#set text(font: SERIF)

#let events = load_events(YEAR)
#let quarters = ((1, 2, 3), (4, 5, 6), (7, 8, 9), (10, 11, 12))

#for q in quarters {
  render_page(YEAR, q, "left", events)
  render_page(YEAR, q, "right", events)
}
