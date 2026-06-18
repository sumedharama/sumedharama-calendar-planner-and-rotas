// ============================================================================
// Sumedhārāma "Morning / Evening Pūja" rota sheet
//
// Four A4-portrait pages, one quarter of the year per page, each showing its
// three months side by side as cut-out strips (weekday · day · writable area)
// to pin on a noticeboard. On moon days the phase icon replaces the day number.
//
// Reproduces the legacy Excel sheet (legacy-reference/2026-06-17_19-46
// morning-evening pujas.png). Colours, fonts and CSV loading are shared via
// lib.typ.
//
//   typst compile morning-evening-puja.typ                  (sys.inputs.year)
//   typst compile --input year=2027 morning-evening-puja.typ
//   typst compile --format png --ppi 150 morning-evening-puja.typ '/tmp/me-{p}.png'
// ============================================================================

#import "lib.typ": *

#let YEAR = int(sys.inputs.at("year", default: str(datetime.today().year())))

// ---------------------------------------------------------------------------
// Tunables (millimetres / points)
// ---------------------------------------------------------------------------
#let PAGE_MARGIN  = 7mm     // margin on every edge
#let WD_W         = 8mm     // weekday-abbreviation column width
#let DAY_W        = 8mm     // day-number / moon column width
#let ROW_H        = 8mm     // day-row height (writing room for Manhã / Tarde)
#let TITLE_FONT   = 9pt     // "Morning / Evening Pūja" strip
#let MONTH_FONT   = 13pt    // month name + year band
#let HEAD_FONT    = 8pt     // "Manhã" / "Tarde" column sub-headers
#let WD_FONT      = 9.5pt   // weekday abbreviation
#let DAY_FONT     = 11pt    // day number
#let MOON_SIZE    = 5mm     // phase icon on moon days
#let RULE         = 0.5pt + GOLDLINE

// ---------------------------------------------------------------------------
// Moon-day lookup: "month-day" -> phase kind (full / new / first / last)
// ---------------------------------------------------------------------------
#let load_moons(year) = {
  let moons = (:)
  for row in event_rows(year) {
    let day_text = row.at("day_text", default: "")
    if day_text not in MOON_KIND { continue }
    let parts = row.at("date", default: "").split("-")
    if parts.len() != 3 { continue }
    let key = str(int(parts.at(1))) + "-" + str(int(parts.at(2)))
    moons.insert(key, MOON_KIND.at(day_text))
  }
  moons
}

// ---------------------------------------------------------------------------
// One month strip: a self-contained table with its own title, ready to cut out.
// ---------------------------------------------------------------------------
#let month_block(year, month, moons) = {
  let cells = ()

  // repeated title strip + month-name band (span all four columns)
  cells.push(table.cell(colspan: 4, fill: NAVY, inset: (y: 2.6mm))[
    #set align(center + horizon)
    #text(font: SERIF, size: TITLE_FONT, weight: "medium", fill: CREAM,
      tracking: 0.4pt, smallcaps[Morning / Evening Pūja])
  ])
  cells.push(table.cell(colspan: 4, fill: GOLD, inset: (y: 2.4mm))[
    #set align(center + horizon)
    #text(font: SERIF, size: MONTH_FONT, weight: "bold", fill: NAVY,
      MONTHS_PT.at(month - 1) + " " + str(YEAR))
  ])
  // column sub-headers for the two writable pūja columns
  cells.push(table.cell(colspan: 2, fill: NAVY.lighten(82%))[])
  for label in ("Manhã", "Tarde") {
    cells.push(table.cell(fill: NAVY.lighten(82%), inset: (y: 1.8mm))[
      #set align(center + horizon)
      #text(font: SERIF, size: HEAD_FONT, style: "italic", fill: NAVY, label)
    ])
  }

  for d in range(1, days_in_month(year, month) + 1) {
    let wd = datetime(year: year, month: month, day: d).weekday() - 1
    let key = str(month) + "-" + str(d)
    let kind = moons.at(key, default: none)
    // only moon days are highlighted (cream); all other days plain
    let bg = if kind != none { CREAM } else { white }

    cells.push(table.cell(fill: bg)[
      #set align(center + horizon)
      #text(font: SANS, size: WD_FONT, fill: NAVY,
        WEEKDAYS_EN.at(wd).slice(0, 3))
    ])
    cells.push(table.cell(fill: bg)[
      #set align(center + horizon)
      #if kind != none { moon(kind, size: MOON_SIZE) } else {
        text(font: SANS, size: DAY_FONT, weight: "medium", fill: NAVY, str(d))
      }
    ])
    // writable areas: morning then evening pūja roster
    cells.push(table.cell(fill: white)[])
    cells.push(table.cell(fill: white)[])
  }

  table(
    columns: (WD_W, DAY_W, 1fr, 1fr),
    rows: (auto, auto, auto) + (ROW_H,) * days_in_month(year, month),
    stroke: RULE,
    ..cells,
  )
}

// ---------------------------------------------------------------------------
// One A4 page: the three months of quarter q (0..3), side by side.
// ---------------------------------------------------------------------------
#let quarter_page(q) = {
  let moons = load_moons(YEAR)
  // no gutter: adjacent strips share an edge, so a single cut separates them
  grid(
    columns: (1fr, 1fr, 1fr),
    ..range(q * 3 + 1, q * 3 + 4).map(m => month_block(YEAR, m, moons)),
  )
}

// ---------------------------------------------------------------------------
// Document
// ---------------------------------------------------------------------------
#set page(width: 210mm, height: 297mm, margin: PAGE_MARGIN, fill: white)
#set text(font: SERIF, fill: NAVY)

#for q in range(4) {
  if q > 0 { pagebreak() }
  quarter_page(q)
}
