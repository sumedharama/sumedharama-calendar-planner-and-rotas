// ============================================================================
// Shared helpers for the Sumedhārāma calendar documents
//
// Imported by both wall-planner.typ and moon-days.typ to avoid duplicating the
// colour scheme, fonts, localisation tables, moon glyph and CSV loading.
// ============================================================================

// ---------------------------------------------------------------------------
// Fonts
// ---------------------------------------------------------------------------
#let SERIF = "Alegreya"        // display / month names / event labels
#let SANS  = "Alegreya Sans"   // numbers / weekday letters / notes
#let DAYNUM_FONT = "Hurricane" // decorative script for the day numbers
#let MONTH_FONT  = "Hurricane" // decorative script for the large month names

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

// ---------------------------------------------------------------------------
// CSV loading
// ---------------------------------------------------------------------------
// Raw event rows for a year as a list of dictionaries keyed by CSV header.
#let event_rows(year) = {
  let rows = csv("data/events-" + str(year) + ".csv", delimiter: ";", row-type: dictionary)
  rows
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
