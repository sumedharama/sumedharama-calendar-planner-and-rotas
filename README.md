# Sumedhārāma Calendar Planner and Rotas

Printable calendars and noticeboard rotas for the Sumedhārāma monastery,
generated with [Typst](https://typst.app). Moon phases, uposatha notes and
event days come from one CSV per year in `data/` (2026–2030).

| Document | Source | What it is |
|---|---|---|
| Wall planner | `wall-planner.typ` | Three-month grid per A4 landscape page, split left/right and butted together; 8 pages per year. Portuguese month names. |
| Moon days | `moon-days.typ` | A5 portrait overview of the year's moon days; 4 pages (one per quarter). |
| Morning / evening puja | `morning-evening-puja.typ` | A4 portrait rota, three cut-out month strips per page; 4 pages. |
| Piṇḍapāta | `pindapata.typ` | The same strip format with one writable column; 4 pages. |
| Daily schedule | `daily-schedule.typ` | One A5 page with the daily timetable. |
| Notebook planner | `notebook-planner.typ` | Folded A6 pocket calendar, English only. Printed duplex on A4 and folded twice. See [docs/notebook-planner/README.md](docs/notebook-planner/README.md) for printing and folding. |

## Requirements

- [Typst](https://typst.app)
- Fonts **Alegreya**, **Alegreya Sans** and **Dancing Script** (check with `typst fonts`)
- `pdftk` (joins the years together) and `poppler-utils` (`pdfinfo`, `pdftotext`, `pdfimages`; used by the build and the checks)

## Build everything

```sh
make
```

This empties `dist/` and builds:

- `dist/daily-schedule.pdf`
- `dist/wall-planner-2026-2030.pdf`, `moon-days-…`, `morning-evening-puja-…` and `pindapata-…`: every year in one PDF
- `dist/notebook-planner/notebook-planner-<year>-<variant>.pdf`: for each year, `two-weeks`, `one-week` and their high-contrast black-and-white `-bw` versions
- `dist/sumedharama-calendars-2026-2030.pdf`: all of the above in one file

The years are taken from the `data/events-<year>.csv` files. To build a range
by hand, run `./build.sh 2026 2028`.

## Work on one document

Rebuild a document on every save (the year is 2026; edit the `Makefile` for another):

```sh
make wall-planner
make moon-days
make morning-evening-puja
make pindapata
make daily-schedule
```

The PDF appears in the repository root. Or compile once, for any year:

```sh
typst compile --input year=2027 wall-planner.typ wall-planner.pdf
```

### Notebook planner targets

Output goes to `dist/notebook-planner/`. `YEAR` defaults to 2026.

```sh
make notebook-planner YEAR=2026           # two weeks per A6 panel
make notebook-planner-one-week YEAR=2026  # one week per A6 panel
make notebook-planner-bw YEAR=2026        # high contrast, for laser printers (also notebook-planner-one-week-bw)
make notebook-planner-all                 # all four versions for every year (YEAR=2026 for one)
make notebook-planner-watch YEAR=2026     # rebuild on every save
make notebook-planner-proof               # numbered fold-test sheet
make notebook-planner-verify YEAR=2026    # automatic checks of the finished PDF
make notebook-planner-clean               # delete dist/notebook-planner/
```

## Adding a year

Put a CSV named `data/events-<year>.csv` in `data/` (same format as the
others) and rebuild. No code change is needed.

## For contributors and agents

`CLAUDE.md` (also linked as `AGENTS.md`) describes the data model, the layout
techniques and the pitfalls of each document.
