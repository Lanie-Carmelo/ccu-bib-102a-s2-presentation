# Simplified Makefile for LaTeX project with Pandoc output

PRESENTATION = presentation
PRESFILE = $(PRESENTATION).tex
BIBFILE = references.bib
OUTPUT_DIR = output
SUBMISSIONS_DIR = submissions

# Create submissions directory
submissions-dir:
	mkdir -p $(SUBMISSIONS_DIR)

all: presentation presentation-notes presentation-handout



# Presentation target
presentation: | $(OUTPUT_DIR)
	lualatex -output-directory=$(OUTPUT_DIR) $(PRESFILE)
	cp $(BIBFILE) $(OUTPUT_DIR)/ 2>/dev/null || true
	cd $(OUTPUT_DIR) && biber $(PRESENTATION)
	lualatex -output-directory=$(OUTPUT_DIR) $(PRESFILE)
	lualatex -output-directory=$(OUTPUT_DIR) $(PRESFILE)

# Presentation with notes
presentation-notes: | $(OUTPUT_DIR)
	lualatex -output-directory=$(OUTPUT_DIR) presentation-notes.tex
	cp $(BIBFILE) $(OUTPUT_DIR)/ 2>/dev/null || true
	cd $(OUTPUT_DIR) && biber presentation-notes
	lualatex -output-directory=$(OUTPUT_DIR) presentation-notes.tex
	lualatex -output-directory=$(OUTPUT_DIR) presentation-notes.tex

# Presentation handout (4 slides per page)
presentation-handout: | $(OUTPUT_DIR)
	lualatex -output-directory=$(OUTPUT_DIR) presentation-handout.tex
	cp $(BIBFILE) $(OUTPUT_DIR)/ 2>/dev/null || true
	cd $(OUTPUT_DIR) && biber presentation-handout
	lualatex -output-directory=$(OUTPUT_DIR) presentation-handout.tex
	lualatex -output-directory=$(OUTPUT_DIR) presentation-handout.tex













# Open presentation PDF
view-presentation:
	@if [ -f $(OUTPUT_DIR)/$(PRESENTATION).pdf ]; then \
		sh -c 'cmd.exe /c start "" "$$(wslpath -w $(OUTPUT_DIR)/$(PRESENTATION).pdf)"'; \
	else \
		echo "Error: Presentation PDF not found. Run 'make presentation' first."; \
	fi











# Submissions target (presentation)
submissions-presentation: presentation | submissions-dir
	cp $(OUTPUT_DIR)/$(PRESENTATION).pdf $(SUBMISSIONS_DIR)/$(PRESENTATION)-$(shell date +%Y%m%d-%H%M).pdf
	@echo "✅ Presentation saved to $(SUBMISSIONS_DIR)/$(PRESENTATION)-$(shell date +%Y%m%d-%H%M).pdf"

# Clean target - remove intermediate files
clean:
	rm -f *.aux *.bbl *.blg *.log *.out *.toc *.bcf *.run.xml *.fls *.fdb_latexmk *.synctex.gz
	rm -rf $(OUTPUT_DIR)/*.aux $(OUTPUT_DIR)/*.bbl $(OUTPUT_DIR)/*.blg $(OUTPUT_DIR)/*.log \
		   $(OUTPUT_DIR)/*.out $(OUTPUT_DIR)/*.toc $(OUTPUT_DIR)/*.bcf $(OUTPUT_DIR)/*.run.xml \
		   $(OUTPUT_DIR)/*.fls $(OUTPUT_DIR)/*.fdb_latexmk $(OUTPUT_DIR)/*.synctex.gz

# Distclean target to remove all generated files
distclean: clean
	rm -rf $(OUTPUT_DIR) $(SUBMISSIONS_DIR)

# Ensure output directory exists
$(OUTPUT_DIR):
	mkdir -p $(OUTPUT_DIR)

# Help target
help:
	@echo "Available targets:"
	@echo ""
	@echo "Paper targets:"
	@echo "  pdf          - Build paper PDF using LaTeX"
	@echo "  pdf-pandoc   - Build paper PDF using Pandoc"
	@echo "  html         - Build HTML using Pandoc"
	@echo "  docx         - Build DOCX using Pandoc"
	@echo "  view         - Open paper PDF in default viewer"
	@echo "  submissions  - Copy paper PDF to submissions folder"
	@echo ""
	@echo "Presentation targets:"
	@echo "  presentation         - Build presentation (no notes)"
	@echo "  presentation-notes   - Build presentation with notes below slides"
	@echo "  presentation-handout - Build handout version (4 slides per page)"
	@echo "  view-presentation    - Open presentation PDF"
	@echo "  submissions-presentation - Copy presentation to submissions folder"
	@echo ""
	@echo "Utility targets:"
	@echo "  all          - Build paper PDF, HTML, and DOCX"
	@echo "  build        - Lint, build paper PDF, and view"
	@echo "  watch        - Watch for changes and rebuild"
	@echo "  lint         - Run LaTeX linter"
	@echo "  status       - Show output file information"
	@echo "  clean        - Remove intermediate files"
	@echo "  distclean    - Remove all generated files"
	@echo "  help         - Show this help message"

.PHONY: all presentation presentation-notes presentation-handout clean distclean view-presentation submissions-presentation submissions-dir help
