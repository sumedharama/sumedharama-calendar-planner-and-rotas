// ============================================================================
// notebook-planner-probe.typ — debugging aid, not part of the printed calendar
//
// Renders the parsed data and the week/page model as plain text so they can be
// diffed against the CSV sources. verify.sh compiles it and parses the
// key=value header, so keep that form if you change the output.
//
//   typst compile --input year=2026 notebook-planner-probe.typ /tmp/probe.pdf && pdftotext ...
//   typst compile --features html --format html --input year=2026 notebook-planner-probe.typ /tmp/probe.html
// ============================================================================

#import "lib.typ": *

#let YEAR = int(sys.inputs.at("year", default: "2026"))
#let data = load_year(YEAR)
#let weeks = weeks_for(YEAR, data: data)
#let pages = pages_for(YEAR, data: data)
#let cells = weeks.map(w => w.days).flatten()
#let in_year = cells.filter(d => d.date.year() == YEAR)
#let unique_in_year = {
  let seen = (:)
  for d in in_year { seen.insert(d.date.display("[year]-[month]-[day]"), true) }
  seen.len()
}

#let iso(date) = date.display("[year]-[month]-[day]")
#let label(day) = day.month_abbr + " " + str(day.day)

#set page(paper: "a4", margin: 8mm)
#set text(font: SANS, size: 7pt, fill: NAVY)

== probe — year #YEAR

keys=#data.len() moons=#data.values().filter(d => d.moon != none).len()
events=#data.values().map(d => d.events.len()).sum(default: 0)

weeks=#weeks.len() pages=#pages.len() cell_count=#cells.len()
in_year=#in_year.len() unique_in_year=#unique_in_year
first_week=#iso(weeks.first().start) last_week=#iso(weeks.last().start) last_day=#iso(cells.last().date)

#for (i, page) in pages.enumerate() [
  page #{i + 1}: #{iso(page.weekA.start)} #{label(page.weekA.days.first())} .. #{iso(page.weekA.days.last().date)} #{label(page.weekA.days.last())} |
  #{if page.weekB == none [#{"-"}] else [#{iso(page.weekB.start)} #{label(page.weekB.days.first())} .. #{iso(page.weekB.days.last().date)} #{label(page.weekB.days.last())}]}
  #linebreak()
]

= rows

#linebreak()
#for (key, entry) in data [
  #key  #(entry.moon)  #entry.events.join("; ")
  #linebreak()
]
