.PHONY: build clean reset generate-tex generate-content fix-references all

# Complete build: CSV -> TeX -> Content -> Fix References -> PDFs
all: generate-tex generate-content fix-references build

# Generate student .tex files from CSV
generate-tex:
	@echo "Generating student .tex files from CSV..."
	python3 csv_to_tex_entries.py -v

# Generate _content.tex versions from standalone .tex files
generate-content:
	@echo "Extracting content versions..."
	@# Student content files
	@cd student_content && \
	for file in *.tex; do \
		if [ "$$file" != "*_content.tex" ] && ! echo "$$file" | grep -q "_content.tex$$" && grep -q "^\\\\documentclass" "$$file" 2>/dev/null; then \
			sed -n '/^\\begin{document}/,/^\\end{document}/p' "$$file" | sed '1d;$$d' > "$${file%.tex}_content.tex"; \
		fi; \
	done
	@# Welcome files
	@cd common_content && \
	for file in Welcome_*.tex; do \
		if ! echo "$$file" | grep -q "_content.tex$$" && grep -q "^\\\\documentclass" "$$file" 2>/dev/null; then \
			sed -n '/^\\begin{document}/,/^\\end{document}/p' "$$file" | sed '1d;$$d' > "$${file%.tex}_content.tex"; \
		fi; \
	done
	@# Programme files
	@cd output && \
	for file in BSc_*.tex HDip_*.tex MSc_*.tex; do \
		if [ -f "$$file" ] && ! echo "$$file" | grep -q "_content.tex$$" && ! echo "$$file" | grep -q "_projects.tex$$" && grep -q "^\\\\documentclass" "$$file" 2>/dev/null; then \
			sed -n '/^\\begin{document}/,/^\\end{document}/p' "$$file" | sed '1d;$$d' > "$${file%.tex}_content.tex"; \
		fi; \
	done
	@echo "Content extraction complete."

# Fix references in main documents to use _content.tex versions
fix-references:
	@echo "Updating references to use _content.tex files..."
	@# Update main showcase document
	@cd output && \
	sed -i.auto_bak \
		-e 's/\\input{\.\.\/common_content\/Welcome_\([^}]*\)\.tex}/\\input{..\/common_content\/Welcome_\1_content.tex}/g' \
		-e 's/\\input{BSc_H_in_\([^}]*\)\.tex}/\\input{BSc_H_in_\1_content.tex}/g' \
		-e 's/\\input{HDip_in_\([^}]*\)\.tex}/\\input{HDip_in_\1_content.tex}/g' \
		-e 's/\\input{MSc_in_\([^}]*\)}/\\input{MSc_in_\1_content.tex}/g' \
		CExpo_2026_-_Project_Showcase.tex CExpo_2026_-_List_of_Projects.tex 2>/dev/null || true
	@# Update project files to reference student _content.tex
	@cd output && \
	for file in *_projects.tex; do \
		if [ -f "$$file" ]; then \
			sed -i.auto_bak 's/\(\\input{\.\.\/student_content\/[^}]*\)\.tex}/\1_content.tex}/g' "$$file"; \
		fi; \
	done
	@echo "Reference updates complete."

# Build images and PDFs
build:
	$(MAKE) -C student_images build
	$(MAKE) -C student_posters build
	$(MAKE) -C common_images build
	$(MAKE) -C output build

clean:
	$(MAKE) -C student_images clean
	$(MAKE) -C student_posters clean
	$(MAKE) -C common_images clean
	$(MAKE) -C output clean

reset:
	$(MAKE) -C student_images reset
	$(MAKE) -C student_posters reset
	$(MAKE) -C common_images reset
	$(MAKE) -C output reset
