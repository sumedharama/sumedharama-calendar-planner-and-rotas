// ============================================================================
// Sumedhārāma "Daily Schedule" sheet
//
// A single A5-portrait noticeboard listing the monastery's daily timetable,
// styled after legacy-reference/Daily Schedule.png. Each row is an icon, the
// English activity, its time, and the Portuguese name. Page frame, crest and
// row icons are pre-rendered artwork in assets/; colours and fonts are shared
// via lib.typ.
//
//   typst compile daily-schedule.typ
//   typst compile --format png --ppi 150 daily-schedule.typ /tmp/ds.png
// ============================================================================

#import "lib.typ": *

// ---------------------------------------------------------------------------
// Building blocks
// ---------------------------------------------------------------------------

// Golden Sumedhārāma droplet logo at the head of the page.
#let crest = align(center, image("assets/sumedharama-logo-only-gold.png", height: 18mm))

// Bilingual title.
#let title_block = align(center)[
  #block(below: 2.5mm,
    text(font: SERIF, size: 24pt, weight: "bold", fill: NAVY, smallcaps[Daily Schedule]))
  #text(font: SERIF, size: 16pt, weight: "semibold", fill: GOLD, smallcaps[Horário Diário])
]

// Lotus rule used to separate title from the timetable.
#let separator(w) = align(center, image("assets/horizontal-separator-lotus.png", width: w))

// The timetable, in order: (icon, English, time, Portuguese).
// `time` and `pt` are content so a row can carry two lines.
#let SCHEDULE = (
  ("morning-puja",      [Morning Pūja],      [5:00],          [Pūja da Manhã]),
  ("morning-chores",    [Morning Chores],    [6:20 – 7:00],   [Tarefas da Manhã]),
  ("breakfast",         [Breakfast],         [7:15 – 7:45],   [Pequeno-almoço]),
  ("breakfast-wash-up", [Breakfast Wash Up], [7:45 – 8:00],   [Limpeza do Pequeno-almoço]),
  ("work-period",       [Work Period],       [8:00 – 10:45],  [Período de Trabalho]),
  ("gather",            [Gather in the Hall],[10:45],         [Reunir no Salão]),
  ("meal",              [Meal],              [11:00],         [Refeição]),
  ("meal-wash-up",      [Meal Wash Up],      [Start by 12:00 \ or before],
                                             [Limpeza da Refeição \ Começar até às 12:00 ou antes]),
  ("evening-puja",      [Evening Pūja],      [19:30],         [Pūja da Noite]),
)

// Portuguese-name cell: text preceded by a short vertical gold rule that stops
// well short of the horizontal row separators (a gap above and below). The rule
// is a fixed height, centred in the row, so the gaps stay even across rows.
#let name_cell(pt) = grid(
  columns: (auto, 1fr),
  column-gutter: 4mm,
  align: (left + horizon, left + horizon),
  rect(width: 0.6pt, height: 8mm, fill: GOLDLINE, stroke: none),
  text(font: SERIF, size: 10.5pt, fill: NAVY, pt),
)

#let schedule_table = {
  let rows = ()
  for (icon, en, time, pt) in SCHEDULE {
    rows.push(image("assets/icon-" + icon + ".png", width: 9mm))
    rows.push(text(font: SERIF, size: 11.5pt, weight: "medium", fill: NAVY, en))
    rows.push(text(font: SANS, size: 10pt, fill: NAVY, time))
    rows.push(name_cell(pt))
  }
  table(
    columns: (auto, auto, 25mm, 1fr),
    align: (center + horizon, left + horizon, center + horizon, left + horizon),
    inset: (x: 1.5mm, y: 2.0mm),
    // Gold hairline between every pair of rows.
    stroke: (_, y) => if y > 0 { (top: 0.5pt + GOLDLINE) },
    ..rows,
  )
}

// Closing blessing.
#let blessing = align(center)[
  #separator(50mm)
  #set par(leading: 0.5em)
  #text(font: SERIF, size: 9pt, fill: NAVY)[May all beings be happy and at peace.]
  #linebreak()
  #text(font: SERIF, size: 9pt, style: "italic", fill: NAVY)[Que todos os seres sejam felizes e em paz.]
]

// ---------------------------------------------------------------------------
// Document
// ---------------------------------------------------------------------------
#set page(
  width: 148mm, height: 210mm,
  margin: (x: 13mm, top: 13mm, bottom: 12mm),
  fill: white,
  background: image("assets/moon-days-background.png", width: 100%, height: 100%),
)
#set text(font: SERIF, fill: NAVY)

#crest
#v(1mm)
#title_block
#separator(56mm)
#v(-2mm)
#schedule_table

#place(bottom + center, blessing)
