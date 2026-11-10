#!/usr/bin/env bash
#
# Repeatable acceptance checks for one year of the folded A6 calendar.
#
#   ./notebook-planner-verify.sh 2026            or            make notebook-planner-verify YEAR=2026
#
# Builds dist/notebook-planner/A6/notebook-planner-A6-<year>-two-weeks.pdf, then checks the page count, the week and
# day-cell model, the date labels in the PDF, duplicate days, moon glyphs and
# that no build input points outside this repository. Exit status is 0 only
# when every check passes.

set -euo pipefail
cd "$(dirname "$0")"

if [ "$#" -ne 1 ]; then
  echo "usage: ./notebook-planner-verify.sh <year>" >&2
  exit 2
fi
YEAR=$1

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

PDF="dist/notebook-planner/A6/notebook-planner-A6-$YEAR-two-weeks.pdf"
pass=0
fail=0
ok()  { pass=$((pass + 1)); printf 'PASS  %s\n' "$*"; }
no()  { fail=$((fail + 1)); printf 'FAIL  %s\n' "$*"; }
check() { # check <ok|no> <description>
  if [ "$1" = ok ]; then ok "$2"; else no "$2"; fi
}

# --- build -----------------------------------------------------------------
start=$(date +%s%N)
if ! ./notebook-planner-build.sh "$YEAR" > "$WORK/build.log" 2>&1; then
  cat "$WORK/build.log"
  no "build of $YEAR failed"
  exit 1
fi
stop=$(date +%s%N)
elapsed=$(awk -v a="$start" -v b="$stop" 'BEGIN { printf "%.2f", (b - a) / 1e9 }')
ok "build succeeded in ${elapsed}s"

# --- model numbers come from the probe, so the check is independent of the
# --- panel renderer
typst compile --input year="$YEAR" notebook-planner-probe.typ "$WORK/probe.pdf"
pdftotext -raw "$WORK/probe.pdf" "$WORK/probe.txt"
model() { grep -o "$1=[0-9]*" "$WORK/probe.txt" | head -n 1 | cut -d= -f2; }
weeks=$(model weeks)
pages=$(model pages)
cells=$(model cell_count)
in_year=$(model in_year)
unique=$(model unique_in_year)
moons=$(model moons)

# --- page count ------------------------------------------------------------
sides=$(pdfinfo "$PDF" | awk '/^Pages:/ { print $2 }')
expect_sides=$(( (pages + 3) / 4 ))
if [ "$sides" -eq "$expect_sides" ]; then
  ok "$sides A4 sides = ceil($pages A6 pages / 4)"
else
  no "$sides A4 sides, expected ceil($pages / 4) = $expect_sides"
fi

slots=$(( sides * 4 ))
if [ "$pages" -le "$slots" ] && [ "$pages" -gt $(( slots - 4 )) ]; then
  ok "$pages A6 pages fit the last of $slots panel slots"
else
  no "$pages A6 pages do not fit $slots panel slots"
fi

if [ "$pages" -eq $(( (weeks + 1) / 2 )) ]; then
  ok "page pairing: $weeks weeks -> $pages pages"
else
  no "page pairing: $weeks weeks should give $(( (weeks + 1) / 2 )) pages, got $pages"
fi

# --- weeks and day cells ---------------------------------------------------
if [ "$cells" -eq $(( weeks * 7 )) ]; then
  ok "week model: $weeks weeks x 7 = $cells day cells"
else
  no "week model: $weeks weeks x 7 = $(( weeks * 7 )), model has $cells"
fi

# --- date labels in the PDF ------------------------------------------------
# One label per day cell: "Nov 9 Mon"; on a moon day the glyph follows it, so the
# text label is unchanged. The year mark sometimes lands on the same
# extraction line as a rotated label, so match anywhere in the text.
MONTHS='Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec'
WEEKDAYS='Mon|Tue|Wed|Thu|Fri|Sat|Sun'
pdftotext -raw "$PDF" "$WORK/calendar.txt"
label_re="($MONTHS) +[0-9]{1,2} +($WEEKDAYS)"
labels=$(grep -oE "$label_re" "$WORK/calendar.txt" | wc -l | tr -d ' ')
if [ "$labels" -eq "$cells" ]; then
  ok "date labels in PDF: $labels = $cells day cells"
else
  no "date labels in PDF: $labels, expected $cells"
fi

numbered_re="($MONTHS) +[0-9]{1,2} +($WEEKDAYS)"
duplicates=$(grep -oE "$numbered_re" "$WORK/calendar.txt" | sort | uniq -d)
if [ -z "$duplicates" ]; then
  ok "no duplicated date labels"
else
  no "duplicated date labels:"; printf '      %s\n' $duplicates
fi

# --- in-year coverage ------------------------------------------------------
days_in_year=$(date -d "$YEAR-12-31" +%j)
if [ "$in_year" -eq "$days_in_year" ] && [ "$unique" -eq "$days_in_year" ]; then
  ok "all $days_in_year dates of $YEAR present exactly once"
else
  no "$in_year dates of $YEAR, $unique unique, expected $days_in_year exactly once"
fi

# --- moon glyphs -----------------------------------------------------------
glyphs=$(pdfimages -list "$PDF" | awk 'NR > 2 && $3 == "image"' | wc -l | tr -d ' ')
if [ "$glyphs" -eq "$moons" ]; then
  ok "moon glyphs: $glyphs = $moons moon days in the data"
else
  no "moon glyphs: $glyphs, expected $moons"
fi

csv_moons=$(grep -E 'Moon|Quarter' "data/events-$YEAR.csv" | cut -d';' -f1 | sort -u | wc -l | tr -d ' ')
if [ "$csv_moons" -eq "$moons" ]; then
  ok "moon data: $csv_moons distinct moon dates in the CSV = $moons in the model"
else
  no "moon data: $csv_moons distinct moon dates in the CSV, model has $moons"
fi

# --- self-contained repository ---------------------------------------------
external=$(grep -rnE "/""home/|sumedharama-calendar-""planner" \
  *.typ build.sh Makefile notebook-planner-build.sh notebook-planner-verify.sh || true)
if [ -z "$external" ]; then
  ok "no build input references a path outside this repository"
else
  no "external path references:"; printf '      %s\n' $external
fi

# --- build time ------------------------------------------------------------
if awk -v t="$elapsed" 'BEGIN { exit !(t < 5) }'; then
  ok "build time ${elapsed}s < 5s"
else
  no "build time ${elapsed}s >= 5s"
fi

# --- summary ---------------------------------------------------------------
echo
if [ "$fail" -eq 0 ]; then
  echo "$YEAR: all $pass checks passed"
  exit 0
fi
echo "$YEAR: $fail of $(( pass + fail )) checks failed"
exit 1
