// ============================================================================
// Folded A6 year calendar — A4 n-up (2 × 2), Typst only
//
//   typst compile --input year=2026 notebook-planner.typ
//
// Each A4 sheet carries four A6 panels per side; printed duplex and folded
// twice it becomes an A6 leaflet whose panels read 1 → 8 in date order.
// See CLAUDE.md (notebook planner section) for the imposition tables and
// docs/notebook-planner/README.md for print settings.
//
// Panel inspection: --input only=23 renders that single panel on an A6 page.
// ============================================================================

#import "lib.typ": *

#let YEAR = int(sys.inputs.at("year", default: str(datetime.today().year())))
#let ONLY = sys.inputs.at("only", default: "")
// Fold-proof mode: the same imposition, with numbered panels instead of week
// columns, so a single printed sheet can be folded and checked by hand.
#let PROOF = sys.inputs.at("proof", default: "0") == "1"
// Layout: "two-weeks" (default, two week columns per A6 panel) or "one-week" (one
// week per A6 panel, seven full-width day rows).
#let LAYOUT = sys.inputs.at("layout", default: "two-weeks")
#assert(LAYOUT in ("two-weeks", "one-week"), message: "layout must be two-weeks or one-week")
// Paper: "A6" (default, 2 × 2 panels per A4 side) or "A7" (4 × 2 panels per A4
// landscape side, one-week layout only, narrower inset).
#let PAPER = sys.inputs.at("paper", default: "A6")
#assert(PAPER in ("A6", "A7"), message: "paper must be A6 or A7")
#let A7 = PAPER == "A7"
#let WEEK_LAYOUT = LAYOUT == "one-week" or A7
// Theme: "colour" (default, navy/gold) or "bw" — high contrast for laser
// printers: 100 % black text and rules, pure black-and-white moon icons, no
// tinted cells.
#let THEME = sys.inputs.at("theme", default: "colour")
#assert(THEME in ("colour", "bw"), message: "theme must be colour or bw")
#let BW = THEME == "bw"

// ---------------------------------------------------------------------------
// Panel geometry — every printable value of the A6 page in one place so the
// print-proof tweaks stay one-line edits.
//
//   panel      105 × 148.5 mm, the A6 leaflet page
//   inset      5 mm uniform: fold/trim zone and printer margin in one value
//   content    95 × 138.5 mm inside the inset
//   columns    two day columns of 47.5 mm
//   rows       seven day rows of 19.786 mm (138.5 / 7)
// ---------------------------------------------------------------------------
// A7: the 4 × 2 grid sits inside a 2 mm margin round the A4 sheet so the date
// labels stay within the printable area; the panels shrink to fit.
#let SHEET_MARGIN = if A7 { 2mm } else { 0mm }
#let PANEL_W = if A7 { (297mm - 2 * SHEET_MARGIN) / 4 } else { 105mm }
#let PANEL_H = if A7 { (210mm - 2 * SHEET_MARGIN) / 2 } else { 148.5mm }
#let INSET = if A7 { 3mm } else { 5mm }
#let CONTENT_W = PANEL_W - 2 * INSET
#let CONTENT_H = PANEL_H - 2 * INSET
#let COL_W = 47.5mm
#let ROW_H = CONTENT_H / 7

// ---------------------------------------------------------------------------
// Typography and colour — serif/sans and the navy/gold scheme come from
// lib.typ; only the sizes and the warm weekend tint are specific to this
// pocket calendar.
// ---------------------------------------------------------------------------
#let DAY_FONT = SANS
#let DAY_SIZE = 7.5pt
#let INK = if BW { black } else { NAVY }
#let ACCENT = if BW { black } else { GOLD }
#let WEEKDAY_FILL = if BW { black } else { NAVY.transparentize(30%) }
#let EVENT_FONT = SERIF
#let EVENT_SIZE = 5.5pt
#let NOTE_SIZE = 6.5pt
#let MOON_SIZE = 4mm     // smaller than the rotas (5mm) to suit the A6 panel
#let YEAR_SIZE = 6.5pt
#let YEAR_TRACKING = 0.6pt

#let RULE = if BW { 0.5pt } else { 0.4pt }
#let RULE_COLOR = if BW { black } else { GOLDLINE }
#let WEEKEND_TINT = if BW { none } else { rgb("#faf6ec") }

// Padding inside a day cell. It sits within the panel inset, so it only shapes
// the cell's internal breathing room.
#let CELL_PAD_X = if A7 { 0.8mm } else { 1.5mm }
#let CELL_PAD_Y = if A7 { 1mm } else { 1.4mm }
// Height reserved by the date line; the 4 mm moon is centred on it and overflows
// the text height by design, so it needs the top padding above it.
#let DATE_H = 4.6mm

// ---------------------------------------------------------------------------
// Day cell
// ---------------------------------------------------------------------------
#let is_weekend(day) = day.weekday_abbr == "Sat" or day.weekday_abbr == "Sun"

// "Nov 9 Mon" — on a moon day the glyph follows the date: "Nov 9 Mon [🌕]".
// The moon icon is larger than the text, so it sits in a box whose layout
// height matches the text (DAY_SIZE) and whose baseline aligns with it.
// The icon itself is centred via place() and overflows the box visually —
// the enclosing day_row is a fixed-height block, so overflow is safe and
// every row stays the same height whether or not a moon is present.
#let day_label(day) = box[
  #text(font: DAY_FONT, size: DAY_SIZE, weight: "medium", fill: INK, day.month_abbr)
  #h(1.5pt)
  #text(font: DAY_FONT, size: DAY_SIZE, weight: "medium", fill: INK, str(day.day))
  #h(1.5pt)
  #text(font: DAY_FONT, size: DAY_SIZE, fill: WEEKDAY_FILL, day.weekday_abbr)
  #if day.moon != none [
    #h(1.5pt)
    #box(
      width: MOON_SIZE,
      height: DAY_SIZE,
      baseline: DAY_SIZE * 0.2,
      place(horizon + center, if BW { moon_bw(day.moon, size: MOON_SIZE) } else { moon(day.moon, size: MOON_SIZE) }),
    )
    // Uposatha info after the full / new moon icon, e.g. "15d H 8/8".
    #if day.note != "" {
      h(1.5pt)
      text(font: DAY_FONT, size: NOTE_SIZE, weight: "medium", fill: INK, day.note)
    }
  ]
]

// One day row: date line at the top-left, event labels beneath it, optional
// weekend tint, and the hairline at the bottom. The row is a fixed-height
// block, so a long event label is clipped rather than pushing the next row.
#let day_row(day, rule: true, w: COL_W) = block(
  width: w,
  height: ROW_H,
  fill: if is_weekend(day) { WEEKEND_TINT } else { none },
  {
    place(top + left, dx: CELL_PAD_X, dy: CELL_PAD_Y, day_label(day))

    if day.events.len() > 0 {
      place(
        top + left,
        dx: CELL_PAD_X,
        dy: CELL_PAD_Y + DATE_H,
        block(
          width: w - 2 * CELL_PAD_X,
          height: ROW_H - CELL_PAD_Y - DATE_H,
          clip: true,
          {
            for (i, event) in day.events.enumerate() {
              if i > 0 { linebreak() }
              // A box never wraps, so a long name runs past the column and is
              // cut by the enclosing clip instead of shrinking the row.
              box(text(font: EVENT_FONT, size: EVENT_SIZE, style: "italic", fill: INK, event))
            }
          },
        ),
      )
    }

    if rule {
      place(
        bottom + left,
        line(start: (0pt, 0pt), end: (w, 0pt), stroke: RULE + RULE_COLOR),
      )
    }
  },
)

// A week is one column: seven stacked day rows, ruled between them.
// `w` is the column width: half the content width, or all of it in one-week layout.
#let week_column(week, w: COL_W) = block(
  width: w,
  height: CONTENT_H,
  {
    for (i, day) in week.days.enumerate() {
      place(top + left, dy: i * ROW_H, day_row(day, rule: i < 6, w: w))
    }
  },
)

// ---------------------------------------------------------------------------
// Panel — one A6 page: two week columns inside the 5 mm inset, a gold divider
// between them and the year mark in the bottom-right corner.
//
// In fold-proof mode the panel is replaced by a huge page number and an arrow
// pointing at the panel's top edge, so the imposition can be traced after
// folding. The rotation flags are applied to this panel exactly as to a real
// one.
// ---------------------------------------------------------------------------
#let proof_panel(n) = box(
  width: PANEL_W,
  height: PANEL_H,
  clip: true,
  fill: white,
  {
    place(
      center + horizon,
      text(font: SANS, size: 90pt, weight: "bold", fill: INK, str(n)),
    )
    place(
      top + center,
      dy: 8mm,
      text(font: SANS, size: 24pt, weight: "bold", fill: ACCENT, "↑"),
    )
  },
)

#let panel(page, number) = if PROOF {
  proof_panel(number)
} else {
  box(
    width: PANEL_W,
    height: PANEL_H,
    clip: true,
    fill: white,
    {
      place(
        top + left,
        dx: INSET,
        dy: INSET,
        block(
          width: CONTENT_W,
          height: CONTENT_H,
          {
            place(top + left, week_column(page.weekA, w: if WEEK_LAYOUT { CONTENT_W } else { COL_W }))
            if page.weekB != none {
              place(top + left, dx: COL_W, week_column(page.weekB))
              place(
                top + left,
                dx: COL_W,
                line(start: (0pt, 0pt), end: (0pt, CONTENT_H), stroke: RULE + RULE_COLOR),
              )
            }
            place(
              bottom + right,
              text(font: SANS, size: YEAR_SIZE, fill: ACCENT, tracking: YEAR_TRACKING, str(YEAR)),
            )
          },
        ),
      )
    },
  )
}

// ---------------------------------------------------------------------------
// Imposition — four A6 panels per A4 side, flush to the sheet edges.
//
// Corrected after a hand fold; every side is identical. Pages are read bottom-right → top-right
// → top-left → bottom-left:
//
//   ┌──────────────────┬──────────────────┐
//   │  page 3          │  page 2          │
//   │  rotated 180°    │  rotated 180°    │
//   ├──────────────────┼──────────────────┤
//   │  page 4          │  page 1          │
//   │  upright         │  upright         │
//   └──────────────────┴──────────────────┘
//
// Every A4 side uses the same layout. Pages continue sequentially (1–4 on the
// first side, 5–8 on the next, etc.) with no front/back distinction — the
// sheet is unfolded and re-oriented by hand when turning it over.
// ---------------------------------------------------------------------------
#let PAGE_W = if A7 { 297mm } else { 210mm }
#let PAGE_H = if A7 { 210mm } else { 297mm }
#let PER_SIDE = if A7 { 8 } else { 4 }

// Slots in reading order bottom-right → top-right → top-left → bottom-left.
// Every A4 side uses the same layout; pages simply continue 1, 2, 3, 4 …
// with base advancing by four per side. No front/back distinction is needed
// because the sheet is unfolded and re-oriented by hand when turning it over.
//
// A7: 4 × 2 on a landscape A4. Bottom row upright, pages 2-5 left to right; top
// row rotated 180°, pages 1, 8, 7, 6 left to right. Page 1 sits above page 2.
// The sheet is cut along the middle between the two inner columns (pages 8/7
// above 3/4) and folded, so those two columns become flaps.
#let slot_layout(base) = if A7 {(
  (col: 0, row: 0, page: base + 1, rotated: true),
  (col: 1, row: 0, page: base + 8, rotated: true),
  (col: 2, row: 0, page: base + 7, rotated: true),
  (col: 3, row: 0, page: base + 6, rotated: true),
  (col: 0, row: 1, page: base + 2, rotated: false),
  (col: 1, row: 1, page: base + 3, rotated: false),
  (col: 2, row: 1, page: base + 4, rotated: false),
  (col: 3, row: 1, page: base + 5, rotated: false),
)} else {(
  (col: 1, row: 1, page: base + 1, rotated: false),
  (col: 1, row: 0, page: base + 2, rotated: true),
  (col: 0, row: 0, page: base + 3, rotated: true),
  (col: 0, row: 1, page: base + 4, rotated: false),
)}

// One A4 side. Out-of-range page numbers leave the slot blank: white, no
// rules, no year mark.
#let sheet_side(base, pages) = {
  for slot in slot_layout(base) {
    if slot.page <= pages.len() {
      let content = panel(pages.at(slot.page - 1), slot.page)
      place(
        top + left,
        dx: SHEET_MARGIN + slot.col * PANEL_W,
        dy: SHEET_MARGIN + slot.row * PANEL_H,
        if slot.rotated { rotate(180deg, content) } else { content },
      )
    }
  }
  // A7: thin cut mark along the middle, between the two inner columns.
  if A7 {
    place(
      top + left,
      dx: SHEET_MARGIN + PANEL_W,
      dy: SHEET_MARGIN + PANEL_H,
      line(length: 2 * PANEL_W, stroke: 0.3pt + black),
    )
  }
}

// ---------------------------------------------------------------------------
// Document
// ---------------------------------------------------------------------------
// Proof mode ignores the year's data and forces 32 numbered panels (8 sides:
// four sheets, front and back) so that every slot of every sheet is filled and
// can be traced after folding. The imposition itself is unchanged.
#let PROOF_PANELS = 32

#let data = if PROOF { none } else { load_year(YEAR) }
#let pages = if PROOF {
  range(PROOF_PANELS).map(i => (weekA: none, weekB: none))
} else if WEEK_LAYOUT {
  weeks_for(YEAR, data: data).map(w => (weekA: w, weekB: none))
} else {
  pages_for(YEAR, data: data)
}

#let slide_count = calc.ceil(pages.len() / PER_SIDE)

#set document(
  title: if PROOF { "Calendar fold proof" } else { "Calendar " + str(YEAR) + if BW { " (high contrast)" } else { "" } },
  author: "Sumedhārāma",
)
#set page(
  width: if ONLY == "" { PAGE_W } else { PANEL_W },
  height: if ONLY == "" { PAGE_H } else { PANEL_H },
  margin: 0mm,
  fill: white,
)
#set text(font: SANS, size: 10pt, fill: INK)

#if ONLY == "" [
  #for side in range(slide_count) {
    if side > 0 { pagebreak() }
    sheet_side(side * PER_SIDE, pages)
  }
] else [
  #place(top + left, panel(pages.at(int(ONLY) - 1), int(ONLY)))
]
