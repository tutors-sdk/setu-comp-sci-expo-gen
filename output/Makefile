TARGETS = \
	CExpo_2026_-_Project_Showcase.pdf \
	CExpo_2026_-_List_of_Projects.pdf

%.pdf: %.tex
	lualatex $<
	lualatex $<
		
build: $(TARGETS)

clean:
	rm -f *.aux *.log *.out *.areas *.rooms *.programmes *.projects *.pdf

reset: clean
