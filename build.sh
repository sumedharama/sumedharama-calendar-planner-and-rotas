#!/usr/bin/env bash

set -euo pipefail

# If both year arguments are given they must start with "20..", otherwise print usage.
# If no arguments are given, derive the range from the data/events-<year>.csv files.
if [[ $# -eq 0 ]]; then
    years=()
    for csv in data/events-20[0-9][0-9].csv; do
        [[ -e "$csv" ]] || continue
        year=${csv#data/events-}
        years+=("${year%.csv}")
    done
    if [[ ${#years[@]} -eq 0 ]]; then
        echo "No data/events-<year>.csv files found." >&2
        exit 1
    fi
    IFS=$'\n' years=($(sort -n <<<"${years[*]}")); unset IFS
    FROM_YEAR=${years[0]}
    TO_YEAR=${years[-1]}
elif [[ $# -eq 2 && "$1" =~ ^20[0-9]{2}$ && "$2" =~ ^20[0-9]{2}$ ]]; then
    FROM_YEAR=$1
    TO_YEAR=$2
else
    echo "Usage: $0 [<from-year> <to-year>]" >&2
    echo "  e.g. $0 2026 2030" >&2
    echo "  with no arguments, the range is taken from data/events-<year>.csv" >&2
    exit 1
fi

echo "Building from year $FROM_YEAR to $TO_YEAR ..."

# Start with a clean dist/ folder for the deliverable PDFs.
DIST=dist
rm -rf "$DIST"
mkdir -p "$DIST"

echo "Creating daily-schedule.pdf ..."
typst compile daily-schedule.typ "$DIST/daily-schedule.pdf"

names=(wall-planner moon-days morning-evening-puja pindapata)

for ((year = FROM_YEAR; year <= TO_YEAR; year++)); do
    for name in "${names[@]}"; do
        echo "Creating $name-$year.pdf ..."
        typst compile --input year=$year $name.typ $name-$year.pdf
    done
done

for name in "${names[@]}"; do
    # Concatenate the years with pdftk to $name-<from-year>-<to-year>.pdf
    echo "Creating $name-$FROM_YEAR-$TO_YEAR.pdf ..."
    inputs=()
    for ((year = FROM_YEAR; year <= TO_YEAR; year++)); do
        inputs+=("$name-$year.pdf")
    done
    pdftk "${inputs[@]}" cat output "$DIST/$name-$FROM_YEAR-$TO_YEAR.pdf"
done

# Clean up, remove the individual year PDFs
for name in "${names[@]}"; do
    for ((year = FROM_YEAR; year <= TO_YEAR; year++)); do
        rm -f "$name-$year.pdf"
    done
done

# Verify that exactly 5 PDF files ended up in dist/
count=$(find "$DIST" -maxdepth 1 -type f -name '*.pdf' | wc -l)
if [[ "$count" -ne 5 ]]; then
    echo "Error: expected 5 PDF files in $DIST/, found $count." >&2
    exit 1
fi
echo "Done: $count PDFs in $DIST/."
