all: diploma

help:
	@echo "Use:"
	@echo "  build   - build all"
	@echo "  diploma - run only LaTeX compilation"
	@echo "  clean"

build: diploma

diploma:
	pdflatex diploma.tex
	bibtex diploma.aux
	pdflatex diploma.tex
	pdflatex diploma.tex

clean:
	for file in `find . -name "*.pdf"`; do rm $$file; done
	for file in `find . -name "*.log"`; do rm $$file; done
	for file in `find . -name "*.aux"`; do rm $$file; done
	for file in `find . -name "*.bbl"`; do rm $$file; done
	for file in `find . -name "*.blg"`; do rm $$file; done
	for file in `find . -name "*.toc"`; do rm $$file; done
	for file in `find . -name "*.out"`; do rm $$file; done
	for file in `find . -name "*.ftm"`; do rm $$file; done
	for file in `find . -name "*.eps"`; do rm $$file; done