# borrowed from
# http://tex.stackexchange.com/questions/40738/how-to-properly-make-a-latex-project

VIEWER=evince

.PHONY: clean main.pdf

PANDOC_SOURCES=$(shell find . -name '*.md')

all: main.pdf

view: main.pdf
	$(VIEWER) out/main.pdf

check: FORCE
	chktex -g0 -l .chktexrc main.tex

main.pdf: out/main.tex
	latexmk \
	  -output-directory=out \
	  -pdf \
	  -xelatex \
	  -bibtex \
	  -interaction=nonstopmode \
	  $<

out/main.tex: main.md
	mkdir -p out
	pandoc \
	  --from markdown-auto_identifiers \
	  --to beamer \
	  --slide-level=3 \
	  --standalone \
	  --listings \
	  $< \
	  -o $@

clean:
	rm -r out

# Fore some reasons that are far behind my understanding of make, The PHONY
# rule doesn't work for the "%.pdf" rule, so let's use this old trick to
# force-rebuild them every time.
FORCE:
