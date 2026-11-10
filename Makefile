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

# ---------------------------------------------------------------------------
# Notebook planner: folded A6 year calendar (notebook-planner.typ).
# Output goes to dist/notebook-planner/. See docs/notebook-planner/README.md.
#
#   make notebook-planner YEAR=2026              two-weeks layout
#   make notebook-planner-one-week YEAR=2026     one week per A6 panel
#   make notebook-planner-bw YEAR=2026           high-contrast B/W (also notebook-planner-one-week-bw)
#   make notebook-planner-all                    4 PDFs per year with data (YEAR=2026 for one)
#   make notebook-planner-A7 YEAR=2026          A7 one-week (also notebook-planner-A7-bw)
#   make notebook-planner-watch YEAR=2026        rebuild on every change
#   make notebook-planner-proof                  fold-proof PDF
#   make notebook-planner-verify YEAR=2026       acceptance checks (needs poppler-utils)
#   make notebook-planner-clean                  remove dist/notebook-planner/
# ---------------------------------------------------------------------------

# Years with data, ascending. `notebook-planner-all` builds every one unless YEAR is given.
NP_YEARS := $(sort $(patsubst data/events-%.csv,%,$(wildcard data/events-*.csv)))
NP_ALL_YEARS := $(if $(filter undefined,$(origin YEAR)),$(NP_YEARS),$(YEAR))

YEAR ?= 2026

.PHONY: notebook-planner notebook-planner-one-week notebook-planner-bw notebook-planner-one-week-bw \
        notebook-planner-all notebook-planner-watch notebook-planner-proof notebook-planner-verify \
        notebook-planner-clean notebook-planner-A7 notebook-planner-A7-bw

notebook-planner-all:
	@for y in $(NP_ALL_YEARS); do \
	  ./notebook-planner-build.sh $$y && ./notebook-planner-build.sh $$y one-week && ./notebook-planner-build.sh $$y bw && ./notebook-planner-build.sh $$y one-week bw && ./notebook-planner-build.sh $$y A7 && ./notebook-planner-build.sh $$y A7 bw || exit 1; \
	done

notebook-planner:
	./notebook-planner-build.sh $(YEAR)

notebook-planner-one-week:
	./notebook-planner-build.sh $(YEAR) one-week

notebook-planner-bw:
	./notebook-planner-build.sh $(YEAR) bw

notebook-planner-one-week-bw:
	./notebook-planner-build.sh $(YEAR) one-week bw

notebook-planner-A7:
	./notebook-planner-build.sh $(YEAR) A7

notebook-planner-A7-bw:
	./notebook-planner-build.sh $(YEAR) A7 bw

notebook-planner-watch:
	@mkdir -p dist/notebook-planner/A6
	typst watch --input year=$(YEAR) notebook-planner.typ dist/notebook-planner/A6/notebook-planner-A6-$(YEAR)-two-weeks.pdf

notebook-planner-proof:
	@mkdir -p dist/notebook-planner/A6
	typst compile --input proof=1 --input year=$(YEAR) notebook-planner.typ dist/notebook-planner/A6/notebook-planner-A6-proof.pdf

notebook-planner-verify:
	./notebook-planner-verify.sh $(YEAR)

notebook-planner-clean:
	rm -rf dist/notebook-planner
