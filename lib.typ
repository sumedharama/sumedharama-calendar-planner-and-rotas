// ============================================================================
// Shared helpers for the Sumedhārāma calendar documents
//
// Imported by every document in this repo (wall planner, moon days, rotas,
// notebook planner) to avoid duplicating the colour scheme, fonts,
// localisation tables, moon glyph and CSV loading.
// ============================================================================

// ---------------------------------------------------------------------------
// Fonts
// ---------------------------------------------------------------------------
#let SERIF = "Alegreya"        // display / month names / event labels
#let SANS  = "Alegreya Sans"   // numbers / weekday letters / notes
#let DAYNUM_FONT = "Dancing Script" // decorative script for the day numbers
#let MONTH_FONT  = "Dancing Script" // decorative script for the large month names

// ---------------------------------------------------------------------------
// Theme colours (harmonised with legacy-reference/Moon Days.png)
// ---------------------------------------------------------------------------
#let NAVY     = rgb("#1f3a5f")  // deep indigo — headings, text
#let GOLD     = rgb("#c2972f")  // accents, ornaments, subtitle
#let GOLDLINE = rgb("#b08a36")  // rules (a touch darker for contrast)
#let CREAM    = rgb("#f5ecd6")  // page background
#let DAYBG    = rgb("#ffffff")  // active day cell (white, writable)
#let DISABLED = rgb("#c6cdd8")  // off-month cells (cool slate)
#let EVENTBG  = rgb("#f1e4bf")  // event-label box fill (warm gold tint)

// ---------------------------------------------------------------------------
// Localisation
// ---------------------------------------------------------------------------
#let MONTHS_PT = (
  "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
  "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro",
)

#let MONTHS_EN = (
  "January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December",
)

// full English weekday names, index 0 = Monday .. 6 = Sunday
#let WEEKDAYS_EN = (
  "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday",
)

// weekday letters for the wall planner, index 0 = Monday .. 6 = Sunday
#let WEEKDAY_LETTERS = ("M", "Tu", "W", "Th", "F", "Sa", "Su")

// three-letter English month abbreviations, index 0 = January
#let MONTHS_ABBR_EN = (
  "Jan", "Feb", "Mar", "Apr", "May", "Jun",
  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
)

// three-letter English weekday abbreviations, index 0 = Monday .. 6 = Sunday
#let WEEKDAYS_ABBR_EN = ("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")

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

// footnote macro -> English text (the calendar is English-only)
#let FOOTNOTE_TEXT_EN = (
  "\\xAjahnChahMemorialDay": "Ajahn Chah Memorial Day",
  "\\xAjahnChahBirthDay":    "Ajahn Chah's Birthday",
  "\\xThaiNewYear":          "Thai New Year (Songkran)",
  "\\xFirstDayOfVassa":      "First Day of Vassa",
  "\\xLastDayOfVassa":       "Last Day of Vassa",
  "\\xMaghaPuja":            "Māgha Pūjā",
  "\\xVesakhaPuja":          "Vesākha Pūjā",
  "\\xAsalhaPuja":           "Āsāḷhā Pūjā",
  "\\xPavarana":             "Pavāraṇā",
)

// day_text moon macro -> phase kind (also the asset file name)
#let MOON_KIND = (
  "\\FullMoon": "full",
  "\\NewMoon": "new",
  "\\FirstQuarter": "first",
  "\\LastQuarter": "last",
)

// lunar-season macro -> short display name (wall planner notes)
#let SEASON_TEXT = (
  "\\xHemanta": "H",
  "\\xGimha":   "G",
  "\\xVassana": "V",
)

// CSV "phase" value -> (asset kind, English name, Portuguese name)
#let PHASE_INFO = (
  "new":    (kind: "new",   en: "New Moon",    pt: "Lua Nova"),
  "waxing": (kind: "first", en: "Waxing Moon", pt: "Lua Crescente"),
  "full":   (kind: "full",  en: "Full Moon",   pt: "Lua Cheia"),
  "waning": (kind: "last",  en: "Waning Moon", pt: "Lua Minguante"),
)

// ---------------------------------------------------------------------------
// Calendar arithmetic
// ---------------------------------------------------------------------------
#let is_leap(y) = (calc.rem(y, 4) == 0 and calc.rem(y, 100) != 0) or calc.rem(y, 400) == 0

#let days_in_month(y, m) = {
  let lengths = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)
  if m == 2 and is_leap(y) { 29 } else { lengths.at(m - 1) }
}

// weekday of the 1st, 0 = Monday .. 6 = Sunday
#let first_weekday(y, m) = datetime(year: y, month: m, day: 1).weekday() - 1

// ordinal suffix, e.g. 1 -> "st", 22 -> "nd", 14 -> "th"
#let ordinal(d) = {
  if calc.rem(d, 100) >= 11 and calc.rem(d, 100) <= 13 { "th" }
  else if calc.rem(d, 10) == 1 { "st" }
  else if calc.rem(d, 10) == 2 { "nd" }
  else if calc.rem(d, 10) == 3 { "rd" }
  else { "th" }
}

// ---------------------------------------------------------------------------
// Moon glyph (artwork extracted from legacy-reference/Moon Days.png)
//   new / first (waxing) / full / last (waning)  ->  assets/moons/<kind>.png
// Clipped to a circle to drop the square corners.
// ---------------------------------------------------------------------------
#let moon(kind, size: 17pt) = box(
  width: size, height: size, clip: true, radius: 50%,
  image("assets/moons/" + kind + ".png", width: size, height: size, fit: "cover"),
)

// Pure black-and-white moon glyph for laser printing: vector, no greys. A black
// ring; the dark part of the disc is solid black, the lit part stays white.
// Same look as the artwork: new = all dark, full = all lit, first = dark on the
// left with a lit crescent on the right, last = the mirror image.
#let moon_bw(kind, size: 17pt) = {
  let ring = 0.5pt
  let a = size / 2 - ring / 2      // radius to the middle of the ring stroke
  let c = size / 2                 // centre
  let q = 0.5523 * a               // cubic control offset for a quarter circle
  box(width: size, height: size, {
    place(dx: ring / 2, dy: ring / 2, circle(radius: a, fill: if kind == "new" { black } else { white }, stroke: ring + black))
    if kind == "first" or kind == "last" {
      // s = 1: dark half on the left (first); -1: on the right (last). The
      // terminator is a half-ellipse bulging 0.4 of the radius into the lit side.
      let s = if kind == "first" { 1 } else { -1 }
      let k = 4 / 3 * 0.4 * a
      place(curve(
        fill: black,
        stroke: none,
        curve.move((c, c - a)),
        curve.cubic((c - s * q, c - a), (c - s * a, c - q), (c - s * a, c)),
        curve.cubic((c - s * a, c + q), (c - s * q, c + a), (c, c + a)),
        curve.cubic((c + s * k, c + a), (c + s * k, c - a), (c, c - a)),
        curve.close(),
      ))
    }
  })
}

// ---------------------------------------------------------------------------
// CSV loading
// ---------------------------------------------------------------------------
// Path of the event CSV for a year.
#let events_path(year) = "data/events-" + str(year) + ".csv"

// Raw event rows for a year as a list of dictionaries keyed by CSV header.
// A missing CSV is a hard error: Typst reports the exact path it searched for.
// build.sh checks the same path first and prints a plain-English message with
// the years that are available.
#let event_rows(year) = {
  let rows = csv(events_path(year), delimiter: ";", row-type: dictionary)
  rows
}

// One pass over the year's CSV into a lookup keyed "<month>-<day>" (unpadded,
// e.g. "3-3"), each entry holding the moon phase kind (or none) and the
// English event labels for that date. Several CSV rows may share a date: the
// events accumulate and the moon phase is never overwritten.
#let load_year(year) = {
  let days = (:)
  for row in event_rows(year) {
    let parts = row.at("date", default: "").trim().split("-")
    if parts.len() != 3 { continue }
    let key = str(int(parts.at(1))) + "-" + str(int(parts.at(2)))

    let moon = none
    let moon_macro = row.at("day_text", default: "").trim()
    if moon_macro in MOON_KIND { moon = MOON_KIND.at(moon_macro) }

    let events = ()
    let macro = row.at("footnote", default: "").trim()
    if macro != "" { events.push(FOOTNOTE_TEXT_EN.at(macro, default: macro)) }

    // Uposatha note for full / new moons, e.g. "15d H 8/8" (days since the
    // last uposatha, season letter, number in season / season total).
    let note = ""
    let phase = row.at("phase", default: "").trim()
    if phase == "full" or phase == "new" {
      let sname = SEASON_TEXT.at(row.at("season", default: "").trim(), default: "")
      let ndays = row.at("days", default: "").trim()
      if sname != "" and ndays != "" and ndays != "0" {
        note = ndays + "d " + sname + " " + row.at("season_number").trim() + "/" + row.at("season_total").trim()
      }
    }

    let seen = days.at(key, default: (moon: none, events: (), note: ""))
    days.insert(key, (
      moon: if seen.moon != none { seen.moon } else { moon },
      events: seen.events + events,
      note: if seen.note != "" { seen.note } else { note },
    ))
  }
  days
}

// ---------------------------------------------------------------------------
// Calendar model: weeks, day entries and page pairing
// ---------------------------------------------------------------------------
// Monday on or before a date (Typst weekday: 1 = Monday … 7 = Sunday).
#let week_start(date) = date - duration(days: date.weekday() - 1)

// One day entry: everything the panel renderer needs for a cell. The lookup is
// year-specific: days that spill into a neighbouring year (the first and last
// weeks) stay plain, so they never inherit that year's moons or events from a
// same month-day.
#let day_entry(date, data, year) = {
  let entry = if date.year() == year {
    let key = str(date.month()) + "-" + str(date.day())
    data.at(key, default: (moon: none, events: (), note: ""))
  } else {
    (moon: none, events: (), note: "")
  }
  (
    date: date,
    day: date.day(),
    month_abbr: MONTHS_ABBR_EN.at(date.month() - 1),
    weekday_abbr: WEEKDAYS_ABBR_EN.at(date.weekday() - 1),
    moon: entry.moon,
    events: entry.events,
    note: entry.note,
  )
}

// Weeks of the calendar: Monday-start weeks from the week containing 1 January
// to the week containing 31 December. Days spilling into the neighbouring years
// are kept, so every displayed week has its seven rows.
#let weeks_for(year, data: none) = {
  let data = if data == none { load_year(year) } else { data }
  let last = datetime(year: year, month: 12, day: 31)
  let weeks = ()
  let monday = week_start(datetime(year: year, month: 1, day: 1))
  while monday <= last {
    let days = ()
    for i in range(7) {
      days.push(day_entry(monday + duration(days: i), data, year))
    }
    weeks.push((start: monday, days: days))
    monday = monday + duration(days: 7)
  }
  weeks
}

// Pages of the calendar: two consecutive weeks side by side, left column first.
// The last page keeps `weekB: none` when the week count is odd.
#let pages_for(year, data: none) = {
  let weeks = weeks_for(year, data: data)
  let pages = ()
  let i = 0
  while i < weeks.len() {
    pages.push((
      weekA: weeks.at(i),
      weekB: if i + 1 < weeks.len() { weeks.at(i + 1) } else { none },
    ))
    i += 2
  }
  pages
}

// Uposatha / moon-day list for the "Upcoming Moon Days" overview.
// Returns the four-phase days (new, waxing, full, waning) in date order as
// dictionaries: (date: datetime, phase: str, info: PHASE_INFO entry).
#let load_moon_days(year) = {
  let out = ()
  for row in event_rows(year) {
    let phase = row.at("phase", default: "")
    if phase not in PHASE_INFO { continue }
    let parts = row.at("date").split("-")
    out.push((
      date: datetime(
        year: int(parts.at(0)), month: int(parts.at(1)), day: int(parts.at(2)),
      ),
      phase: phase,
      info: PHASE_INFO.at(phase),
    ))
  }
  out
}
