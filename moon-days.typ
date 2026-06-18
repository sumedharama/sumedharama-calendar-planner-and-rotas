// ============================================================================
// Sumedhārāma "Moon Days" overview sheet
//
// Four A5-portrait pages, one per quarter of the year, listing the lunar phase
// days (new / waxing / full / waning). Styled after legacy-reference/Moon
// Days.png. Page frame and the wheel/lotus crest are pre-rendered artwork in
// assets/; colours, fonts and CSV loading are shared via lib.typ.
//
//   typst compile moon-days.typ                  (current year)
//   typst compile --input year=2027 moon-days.typ
// ============================================================================

#import "lib.typ": *

#let YEAR = int(sys.inputs.at("year", default: str(datetime.today().year())))

// ---------------------------------------------------------------------------
// Building blocks
// ---------------------------------------------------------------------------

// Pre-rendered crest: dharma wheel flanked by two lotuses.
#let crest = align(center, image("assets/wheel-and-lotuses.png", width: 56mm))

// Bilingual title plus the quarter's month range.
#let title_block(q) = {
  let m1 = MONTHS_EN.at(q * 3)
  let m3 = MONTHS_EN.at(q * 3 + 2)
  align(center)[
    #block(below: 2.2mm, text(font: SERIF, size: 21pt, weight: "bold", fill: NAVY,
      smallcaps[Moon Days] + " " + str(YEAR)))
    #block(below: 2.8mm, text(font: SERIF, size: 14pt, weight: "semibold", fill: GOLD,
      smallcaps[Dias da Lua] + " " + str(YEAR)))
    #text(font: SERIF, size: 11pt, style: "italic", fill: NAVY, m1 + " – " + m3)
  ]
}

// Thin gold rule centred on a small diamond — the legend separators.
#let diamond_rule(w) = align(center, box(width: w, height: 4pt)[
  #place(horizon, line(length: 100%, stroke: 0.5pt + GOLDLINE))
  #place(center + horizon, rotate(45deg, square(size: 2.4pt, fill: GOLD)))
])

// One legend card: a moon over its bilingual phase name.
#let legend_card(phase) = {
  let p = PHASE_INFO.at(phase)
  align(center)[
    #moon(p.kind, size: 10mm)
    #block(above: 1.0mm, below: 1.3mm,
      text(font: SERIF, size: 9.5pt, weight: "bold", fill: NAVY, smallcaps(p.en)))
    #text(font: SERIF, size: 9pt, style: "italic", fill: NAVY, p.pt)
  ]
}

// The left-hand legend column: four phase cards plus the explanation note.
#let legend = {
  set par(leading: 0.45em)
  let sep = { v(0.3mm); diamond_rule(26mm); v(0.3mm) }
  legend_card("new"); sep
  legend_card("waxing"); sep
  legend_card("full"); sep
  legend_card("waning")
  v(2.5mm)
  diamond_rule(22mm)
  v(1.8mm)
  set par(justify: false, leading: 0.5em)
  set text(font: SERIF, size: 8pt, fill: NAVY)
  align(center)[Moon Days are special days for reflection, practice and merit.]
  v(2mm)
  align(center, text(style: "italic")[Os Dias da Lua são dias especiais para reflexão, prática e mérito.])
}

// The dated list of phase days for one quarter (months q*3+1 .. q*3+3).
#let moon_list(q) = {
  let days = load_moon_days(YEAR).filter(d => {
    let m = d.date.month()
    m >= q * 3 + 1 and m <= q * 3 + 3
  })

  let rows = ()
  for d in days {
    let wd = WEEKDAYS_EN.at(d.date.weekday() - 1).slice(0, 3)
    let mn = MONTHS_EN.at(d.date.month() - 1).slice(0, 3)
    let date_str = wd + " " + str(d.date.day()) + ordinal(d.date.day()) + " " + mn
    rows.push(moon(d.info.kind, size: 5.5mm))
    rows.push(text(font: SERIF, size: 8.5pt, fill: NAVY, weight: "medium", date_str))
    rows.push(text(font: SERIF, size: 8.5pt, fill: GOLDLINE)[–])
    rows.push(text(font: SERIF, size: 8.5pt, fill: NAVY)[#d.info.en / #emph(d.info.pt)])
  }

  table(
    columns: (auto, 25mm, auto, 1fr),
    align: (center + horizon, left + horizon, center + horizon, left + horizon),
    inset: (x: 1.3mm, y: 2.1mm),
    stroke: (_, y) => (top: 0.4pt + GOLDLINE),  // hairline rule above every row
    ..rows,
  )
}

// One full A5 page for quarter q (0..3).
#let quarter_page(q) = {
  crest
  v(1mm)
  title_block(q)
  v(3mm)
  grid(
    columns: (27mm, 1fr),
    column-gutter: 4mm,
    legend,
    moon_list(q),
  )
  place(bottom, dx: 31mm, block(width: 83mm, {
    set par(justify: false, leading: 0.5em)
    set text(font: SERIF, size: 6.5pt, fill: NAVY)
    [As datas para o calendário lunar são determinadas por métodos de cálculo tradicional e nem sempre são no mesmo dia das ocorrências astronómicas. Para mais informações consulte: #link("https://splendidmoons.github.io")]
  }))
}

// ---------------------------------------------------------------------------
// Document
// ---------------------------------------------------------------------------
#set page(
  width: 148mm, height: 210mm,
  margin: (x: 17mm, top: 13mm, bottom: 12mm),
  fill: white,
  background: image("assets/moon-days-background.png", width: 100%, height: 100%),
)
#set text(font: SERIF, fill: NAVY)

#for q in range(4) {
  if q > 0 { pagebreak() }
  quarter_page(q)
}
