// ============================================================================
// Sumedhārāma "Upcoming Moon Days" overview sheet
//
// A single-page A4 portrait poster listing the lunar phase days for the year,
// styled after legacy-reference/Moon Days.png — gold double frame with key
// corners, a Dharma-wheel/lotus crest, a bilingual title, a phase legend and
// the dated moon list. Colours, fonts and the CSV loading are shared via lib.typ.
//
//   typst compile moon-days.typ                          (current year, upcoming)
//   typst compile --input year=2027 moon-days.typ
//   typst compile --input from=2026-01-01 moon-days.typ  (list from a given date)
// ============================================================================

#import "lib.typ": *

#let YEAR = int(sys.inputs.at("year", default: str(datetime.today().year())))

// First date to list. Defaults to today (so the sheet shows *upcoming* days);
// override with --input from=YYYY-MM-DD, or set to the year's start.
#let FROM = {
  let s = sys.inputs.at("from", default: "")
  if s == "" { datetime.today() } else {
    let p = s.split("-")
    datetime(year: int(p.at(0)), month: int(p.at(1)), day: int(p.at(2)))
  }
}
#let date_key(d) = d.year() * 10000 + d.month() * 100 + d.day()

// ---------------------------------------------------------------------------
// Decorative primitives (drawn natively — no external ornament artwork)
// ---------------------------------------------------------------------------

// Greek-key style corner bracket, oriented for the top-left corner.
#let key_corner(s) = box(width: s, height: s)[
  #set line(stroke: 1.0pt + GOLD)
  #place(line(start: (26%, 100%), end: (26%, 26%)))
  #place(line(start: (26%, 26%), end: (100%, 26%)))
  #place(line(start: (50%, 100%), end: (50%, 50%)))
  #place(line(start: (50%, 50%), end: (100%, 50%)))
  #place(dx: 70%, dy: 70%, square(size: s * 0.13, fill: GOLD))
]

// Gold double frame with a key bracket at each corner, sized to fill the page.
#let frame(inset: 9mm) = {
  let i2 = inset + 1.6mm
  place(top + left, dx: inset, dy: inset,
    rect(width: 100% - 2 * inset, height: 100% - 2 * inset, stroke: 1.4pt + GOLD))
  place(top + left, dx: i2, dy: i2,
    rect(width: 100% - 2 * i2, height: 100% - 2 * i2, stroke: 0.5pt + GOLD))
  let cs = 12mm
  place(top + left,     dx: inset, dy: inset, key_corner(cs))
  place(top + right,    dx: -inset, dy: inset, rotate(90deg, origin: center, key_corner(cs)))
  place(bottom + right, dx: -inset, dy: -inset, rotate(180deg, origin: center, key_corner(cs)))
  place(bottom + left,  dx: inset, dy: -inset, rotate(270deg, origin: center, key_corner(cs)))
}

// Eight-spoke Dharma wheel.
#let dharma_wheel(d) = box(width: d, height: d)[
  #place(center + horizon, circle(radius: d / 2, stroke: 1.6pt + GOLD))
  #place(center + horizon, circle(radius: d / 2 * 0.34, stroke: 1.4pt + GOLD))
  #place(center + horizon, circle(radius: d / 2 * 0.13, fill: GOLD))
  #for i in range(4) {
    place(center + horizon,
      rotate(i * 45deg, line(start: (0pt, -d / 2), end: (0pt, d / 2), stroke: 1.1pt + GOLD)))
  }
]

// Small stylised lotus (a fan of petals).
#let lotus(w) = {
  let petal = ellipse(width: w * 0.17, height: w * 0.46,
    fill: GOLD.lighten(62%), stroke: 0.5pt + GOLD)
  box(width: w, height: w * 0.52)[
    #for a in (-52deg, -26deg, 0deg, 26deg, 52deg) {
      place(bottom + center, rotate(a, origin: bottom + center, petal))
    }
  ]
}

// Thin gold rule centred on a small diamond — the legend separators.
#let diamond_rule(w) = align(center, box(width: w)[
  #place(horizon, line(length: 100%, stroke: 0.5pt + GOLDLINE))
  #place(center + horizon, rotate(45deg, square(size: 2.4pt, fill: GOLD)))
])

// A moon image inside a gold ring.
#let moon_badge(kind, d) = box(width: d, height: d, baseline: 38%)[
  #place(center + horizon, circle(radius: d / 2, stroke: 0.9pt + GOLD, fill: white))
  #place(center + horizon, moon(kind, size: d * 0.84))
]

// ---------------------------------------------------------------------------
// Content blocks
// ---------------------------------------------------------------------------
#let crest = align(center, box[
  #set align(horizon)
  #lotus(21mm)
  #h(3mm)
  #dharma_wheel(18mm)
  #h(3mm)
  #scale(x: -100%, reflow: false, lotus(21mm))
])

#let title_block = align(center)[
  #block(below: 1.0mm, text(font: SERIF, size: 28pt, weight: "bold", fill: NAVY,
    smallcaps[Upcoming Moon Days] + " " + str(YEAR)))
  #block(text(font: SERIF, size: 19pt, weight: "semibold", fill: GOLD,
    smallcaps[Próximos Dias da Lua] + " " + str(YEAR)))
]

// One legend card: a ringed moon over its bilingual phase name.
#let legend_card(phase) = {
  let p = PHASE_INFO.at(phase)
  align(center)[
    #moon_badge(p.kind, 18mm)
    #block(above: 2.0mm, below: 0.5mm,
      text(font: SERIF, size: 11.5pt, weight: "bold", fill: NAVY, smallcaps(p.en)))
    #text(font: SERIF, size: 10.5pt, style: "italic", fill: NAVY, p.pt)
  ]
}

#let legend = {
  set par(leading: 0.5em)
  let sep = { v(3.4mm); diamond_rule(34mm); v(3.4mm) }
  legend_card("new"); sep
  legend_card("waxing"); sep
  legend_card("full"); sep
  legend_card("waning")
  v(4mm)
  align(center, lotus(11mm))
  v(1.5mm)
  set par(justify: false, leading: 0.55em)
  set text(font: SERIF, size: 10pt, fill: NAVY)
  align(center)[Moon Days are special days for reflection, practice and merit.]
  v(2mm)
  diamond_rule(28mm)
  v(2mm)
  align(center, text(style: "italic")[Os Dias da Lua são dias especiais para reflexão, prática e mérito.])
}

// The dated list of phase days.
#let moon_list = {
  let days = load_moon_days(YEAR).filter(d => date_key(d.date) >= date_key(FROM))

  let rows = ()
  for d in days {
    let wd = WEEKDAYS_EN.at(d.date.weekday() - 1)
    let mn = MONTHS_EN.at(d.date.month() - 1)
    let date_str = wd + " " + str(d.date.day()) + ordinal(d.date.day()) + " " + mn
    rows.push(moon_badge(d.info.kind, 6mm))
    rows.push(text(font: SERIF, size: 11.5pt, fill: NAVY, weight: "medium", date_str))
    rows.push(text(font: SERIF, size: 11.5pt, fill: GOLDLINE)[–])
    rows.push(box(text(font: SERIF, size: 11.5pt, fill: NAVY, d.info.en + " / " + d.info.pt)))
  }

  table(
    columns: (auto, auto, auto, 1fr),
    align: (center + horizon, left + horizon, center + horizon, left + horizon),
    inset: (x: 1.8mm, y: 0.7mm),
    stroke: (_, y) => (top: 0.4pt + GOLDLINE),  // hairline rule above every row
    ..rows,
  )
}

// ---------------------------------------------------------------------------
// Document
// ---------------------------------------------------------------------------
#set page(
  width: 210mm, height: 297mm,
  margin: (x: 17mm, top: 13mm, bottom: 11mm),
  fill: CREAM,
  background: frame(),
)
#set text(font: SERIF, fill: NAVY)

#crest
#title_block
#v(3mm)

#grid(
  columns: (46mm, 1fr),
  column-gutter: 5mm,
  legend,
  moon_list,
)
