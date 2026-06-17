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

// ---------------------------------------------------------------------------
// Tunables (millimetres)
// ---------------------------------------------------------------------------
#let PAGE_MARGIN   = 6mm     // margin on every edge
#let LABEL_W       = 22mm    // width of the rotated month-name column (left page)
#let HEADER_H      = 8mm     // top / bottom weekday strip height
#let GRID_STROKE   = 0.5pt
#let DAY_FONT      = 15pt    // day-number size
#let WEEKDAY_FONT  = 15pt    // weekday letter size
#let FOOT_FONT     = 6.5pt   // footnote size
#let MOON_SIZE     = 15pt

#let GRAY = luma(170)

// ---------------------------------------------------------------------------
// Localisation
// ---------------------------------------------------------------------------
#let MONTHS_PT = (
  "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
  "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro",
)

// weekday letters, index 0 = Monday .. 6 = Sunday (English abbreviations)
#let WEEKDAY_LETTERS = ("M", "Tu", "W", "Th", "F", "Sa", "Su")

// footnote macro -> Portuguese text (see data/text-portuguese.tex)
#let FOOTNOTE_TEXT = (
  "\\xAjahnChahMemorialDay": "Dia em memória de Ajahn Chah",
  "\\xAjahnChahBirthDay":    "Aniversário de Ajahn Chah",
  "\\xThaiNewYear":          "Ano Novo Tailandês, Songkran",
  "\\xFirstDayOfVassa":      "Primeiro dia do Vassa",
  "\\xLastDayOfVassa":       "Último dia do Vassa",
  "\\xMaghaPuja":            "Māgha Pūjā",
  "\\xVesakhaPuja":          "Vesākha Pūjā",
  "\\xAsalhaPuja":           "Āsāḷhā Pūjā",
  "\\xPavarana":             "Pavāraṇā",
)

// day_text moon macro -> phase kind
#let MOON_KIND = (
  "\\FullMoon": "full",
  "\\NewMoon": "new",
  "\\FirstQuarter": "first",
  "\\LastQuarter": "last",
)

// ---------------------------------------------------------------------------
// Calendar helpers
// ---------------------------------------------------------------------------
#let is_leap(y) = (calc.rem(y, 4) == 0 and calc.rem(y, 100) != 0) or calc.rem(y, 400) == 0

#let days_in_month(y, m) = {
  let lengths = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)
  if m == 2 and is_leap(y) { 29 } else { lengths.at(m - 1) }
}

// weekday of the 1st, 0 = Monday .. 6 = Sunday
#let first_weekday(y, m) = datetime(year: y, month: m, day: 1).weekday() - 1

// ---------------------------------------------------------------------------
// Moon glyphs
// ---------------------------------------------------------------------------
#let moon(kind) = {
  let s = MOON_SIZE
  if kind == "full" {
    box(circle(radius: s / 2, stroke: GRID_STROKE + black, fill: white))
  } else if kind == "new" {
    box(circle(radius: s / 2, stroke: GRID_STROKE + black, fill: black))
  } else {
    let side = if kind == "first" { left } else { right }
    box(width: s, height: s, {
      place(center + horizon,
        box(width: s, height: s, clip: true, radius: 50%, fill: white,
          place(side + horizon, rect(width: s / 2, height: s, fill: black))))
      place(center + horizon, circle(radius: s / 2, stroke: GRID_STROKE + black))
    })
  }
}

// ---------------------------------------------------------------------------
// Event data: build a lookup keyed "month-day" -> (kind, footnotes)
// ---------------------------------------------------------------------------
#let load_events(year) = {
  let rows = csv("data/events-" + str(year) + ".csv", delimiter: ";")
  let events = (:)
  for row in rows.slice(1) {       // skip header
    if row.len() < 3 { continue }
    let date = row.at(0)
    if date == "" { continue }
    let parts = date.split("-")
    let m = int(parts.at(1))
    let d = int(parts.at(2))
    let key = str(m) + "-" + str(d)
    let entry = events.at(key, default: (kind: none, foot: ()))
    let day_text = row.at(1)
    if day_text in MOON_KIND { entry.kind = MOON_KIND.at(day_text) }
    let foot = row.at(2)
    if foot != "" {
      let txt = FOOTNOTE_TEXT.at(foot, default: foot)
      entry.foot = entry.foot + (txt,)
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
#let weekday_cell(letter) = table.cell(fill: GRAY)[
  #set align(center + horizon)
  #text(size: WEEKDAY_FONT)[#letter]
]

#let empty_cell = table.cell(fill: GRAY)[]

#let day_cell(d, entry) = table.cell(fill: white)[
  #set align(center + top)
  #pad(top: 1.5mm)[
    #if entry != none and entry.kind != none {
      moon(entry.kind)
    } else {
      text(size: DAY_FONT, weight: "bold")[#d]
    }
    #if entry != none and entry.foot.len() > 0 {
      v(0.6mm)
      set text(size: FOOT_FONT)
      set par(leading: 0.3em, justify: false)
      set align(center)
      for f in entry.foot {
        block(width: 100%, inset: (x: 0.5mm))[\* #f]
      }
    }
  ]
]

// label cell with small abbreviation (top) + large rotated month name
#let month_label(name) = table.cell(fill: GRAY)[
  #set align(center + horizon)
  #grid(rows: (auto, 1fr), row-gutter: 2mm,
    pad(top: 1mm)[#text(size: 8pt, weight: "bold")[#name]],
    align(center + horizon)[#rotate(-90deg, reflow: true)[
      #text(size: 22pt, weight: "bold")[#name]
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
    header.push(table.cell(fill: GRAY)[
      #set align(center + horizon)
      #text(size: 12pt)[#str(year)]
    ])
  }
  for p in cols { header.push(weekday_cell(wd_letter(p))) }

  let footer = ()
  if side == "left" { footer.push(empty_cell) }
  for p in cols { footer.push(weekday_cell(wd_letter(p))) }

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
  )
  table(
    columns: tracks,
    rows: (HEADER_H, 1fr, 1fr, 1fr, HEADER_H),
    stroke: GRID_STROKE + black,
    inset: 0pt,
    ..header,
    ..body,
    ..footer,
  )
}

// ---------------------------------------------------------------------------
// Document
// ---------------------------------------------------------------------------
#set text(font: "DejaVu Sans")

#let events = load_events(YEAR)
#let quarters = ((1, 2, 3), (4, 5, 6), (7, 8, 9), (10, 11, 12))

#for q in quarters {
  render_page(YEAR, q, "left", events)
  render_page(YEAR, q, "right", events)
}
