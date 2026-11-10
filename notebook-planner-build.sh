#!/usr/bin/env bash
#
# Build the folded A6 notebook planner for one year.
#
#   ./notebook-planner-build.sh 2026            -> dist/notebook-planner/notebook-planner-2026-two-weeks.pdf
#   make notebook-planner YEAR=2027    -> dist/notebook-planner/notebook-planner-2027-two-weeks.pdf
#   ./notebook-planner-build.sh 2026 one-week   -> dist/notebook-planner/notebook-planner-2026-one-week.pdf (one week per A6 panel)
#   ./notebook-planner-build.sh 2026 one-week bw -> dist/notebook-planner/notebook-planner-2026-one-week-bw.pdf (high contrast, laser)
#
# The year must have a matching data file, data/events-<year>.csv. See
# docs/notebook-planner/README.md for adding a new year. Printing and folding instructions are also
# in that file.

set -euo pipefail
cd "$(dirname "$0")"

# Years that have a data file, ascending, one per line.
available_years() {
  local csv
  for csv in data/events-????.csv; do
    [ -e "$csv" ] || continue
    local name
    name=$(basename "$csv" .csv)
    printf '%s\n' "${name#events-}"
  done | sort
}

# Report a problem together with the years that can be built, then exit 1.
fail() {
  local years
  years=$(available_years | paste -sd ',' - | sed 's/,/, /g')
  echo "notebook-planner-build.sh: $*" >&2
  if [ -n "$years" ]; then
    echo "Available years: $years" >&2
  else
    echo "No data files found in data/ (expected data/events-<year>.csv)." >&2
  fi
  exit 1
}

if [ "$#" -lt 1 ] || [ "$#" -gt 3 ]; then
  fail "expected the year and optional words, e.g. ./notebook-planner-build.sh 2026 [one-week] [bw]"
fi

YEAR=$1
if ! [[ "$YEAR" =~ ^[0-9]{4}$ ]]; then
  fail "not a four-digit year: '$YEAR'"
fi
shift
LAYOUT=two-weeks
THEME=colour
for opt in "$@"; do
  case "$opt" in
    one-week) LAYOUT=one-week ;;
    bw) THEME=bw ;;
    *) fail "unknown option '$opt' (use one-week and/or bw)" ;;
  esac
done

if [ ! -f "data/events-$YEAR.csv" ]; then
  fail "No data file data/events-$YEAR.csv — add it or choose a year in $(available_years | head -n 1)–$(available_years | tail -n 1)."
fi

mkdir -p dist/notebook-planner
OUT="dist/notebook-planner/notebook-planner-$YEAR"
OUT="$OUT-$LAYOUT"
[ "$THEME" = bw ] && OUT="$OUT-bw"
OUT="$OUT.pdf"

start=$SECONDS
typst compile --input year="$YEAR" --input layout="$LAYOUT" --input theme="$THEME" notebook-planner.typ "$OUT"
elapsed=$((SECONDS - start))

if command -v pdfinfo >/dev/null 2>&1; then
  sides=$(pdfinfo "$OUT" | awk '/^Pages:/ { print $2 }')
  sheets=$(( (sides + 1) / 2 ))
  echo "$OUT — $sides A4 sides ($sheets sheets), built in ${elapsed}s"
else
  echo "$OUT — built in ${elapsed}s (install pdfinfo to print the page count)"
fi
