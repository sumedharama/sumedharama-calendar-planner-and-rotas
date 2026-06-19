all:
	./build.sh

wall-planner:
	typst watch --input year=2026 wall-planner.typ wall-planner.pdf

moon-days:
	typst watch --input year=2026 moon-days.typ moon-days.pdf

morning-evening-puja:
	typst watch --input year=2026 morning-evening-puja.typ morning-evening-puja.pdf

pindapata:
	typst watch --input year=2026 pindapata.typ pindapata.pdf

daily-schedule:
	typst watch daily-schedule.typ daily-schedule.pdf
