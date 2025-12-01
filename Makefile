# Makefile for Beamer presentation

PRESENTATION = presentation
PRESFILE = $(PRESENTATION).tex
BIBFILE = references.bib
OUTPUT_DIR = output
SUBMISSIONS_DIR = submissions
CSL_FILE = apa.csl
LUA_FILTER = add-refs-heading.lua

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













# Open presentation PDF (cross-platform)
view-presentation:
	@if [ -f $(OUTPUT_DIR)/$(PRESENTATION).pdf ]; then \
		if command -v wslpath >/dev/null 2>&1; then \
			cmd.exe /c start "" "$$(wslpath -w $(OUTPUT_DIR)/$(PRESENTATION).pdf)"; \
		elif command -v xdg-open >/dev/null 2>&1; then \
			xdg-open $(OUTPUT_DIR)/$(PRESENTATION).pdf; \
		elif command -v open >/dev/null 2>&1; then \
			open $(OUTPUT_DIR)/$(PRESENTATION).pdf; \
		else \
			echo "PDF is at: $(OUTPUT_DIR)/$(PRESENTATION).pdf"; \
		fi; \
	else \
		echo "Error: Presentation PDF not found. Run 'make presentation' first."; \
	fi

# Alias for view-presentation
view: view-presentation

# Build HTML from presentation using Pandoc
html: | $(OUTPUT_DIR)
	pandoc $(PRESFILE) -o $(OUTPUT_DIR)/$(PRESENTATION).html \
		--standalone \
		--citeproc \
		--bibliography=$(BIBFILE) \
		--csl=$(CSL_FILE) \
		--metadata lang=en-US \
		--lua-filter=$(LUA_FILTER)
	@echo "✅ HTML saved to $(OUTPUT_DIR)/$(PRESENTATION).html"

# Build DOCX from presentation using Pandoc
docx: | $(OUTPUT_DIR)
	pandoc $(PRESFILE) -o $(OUTPUT_DIR)/$(PRESENTATION).docx \
		--citeproc \
		--bibliography=$(BIBFILE) \
		--csl=$(CSL_FILE) \
		--lua-filter=$(LUA_FILTER)
	@echo "✅ DOCX saved to $(OUTPUT_DIR)/$(PRESENTATION).docx"











# Submissions target (presentation)
submissions-presentation: presentation | submissions-dir
	cp $(OUTPUT_DIR)/$(PRESENTATION).pdf $(SUBMISSIONS_DIR)/$(PRESENTATION)-$(shell date +%Y%m%d-%H%M).pdf
	@echo "✅ Presentation saved to $(SUBMISSIONS_DIR)/$(PRESENTATION)-$(shell date +%Y%m%d-%H%M).pdf"

# Alias for submissions-presentation
submissions: submissions-presentation

# Build target - create PDF, HTML, and DOCX versions
build: presentation html docx
	@echo "✅ Build complete: PDF, HTML, and DOCX created in $(OUTPUT_DIR)/"

# Quick build - single pass for faster iteration (no bibliography update)
quick: | $(OUTPUT_DIR)
	lualatex -output-directory=$(OUTPUT_DIR) $(PRESFILE)
	@echo "✅ Quick build complete (single pass, no biber)"

# Watch target - auto-rebuild on file changes
watch:
	@echo "Watching for changes to .tex and .bib files..."
	@echo "Press Ctrl+C to stop."
	@while true; do \
		inotifywait -q -e modify $(PRESFILE) $(BIBFILE) $(PRESENTATION)-notes.tex $(PRESENTATION)-handout.tex 2>/dev/null || \
		fswatch -1 $(PRESFILE) $(BIBFILE) $(PRESENTATION)-notes.tex $(PRESENTATION)-handout.tex 2>/dev/null || \
		(echo "Install inotify-tools (Linux) or fswatch (macOS) for watch functionality" && exit 1); \
		echo "Change detected, rebuilding..."; \
		$(MAKE) presentation; \
	done

# Check target - validate PDF and show metadata
check:
	@if [ -f $(OUTPUT_DIR)/$(PRESENTATION).pdf ]; then \
		echo "PDF Metadata:"; \
		pdfinfo $(OUTPUT_DIR)/$(PRESENTATION).pdf 2>/dev/null || echo "  (pdfinfo not installed)"; \
		echo ""; \
		echo "File size: $$(ls -lh $(OUTPUT_DIR)/$(PRESENTATION).pdf | awk '{print $$5}')"; \
		echo "Page count: $$(pdfinfo $(OUTPUT_DIR)/$(PRESENTATION).pdf 2>/dev/null | grep Pages | awk '{print $$2}' || echo 'unknown')"; \
	else \
		echo "Error: PDF not found. Run 'make presentation' first."; \
	fi

# Lint target - run LaTeX linter
lint:
	@echo "Running chktex on presentation files..."
	-chktex -q $(PRESFILE)
	-chktex -q $(PRESENTATION)-notes.tex
	-chktex -q $(PRESENTATION)-handout.tex
	@echo "Lint complete."

# Status target - show output file information
status:
	@echo "Output file status:"
	@echo ""
	@if [ -d $(OUTPUT_DIR) ]; then \
		ls -lh $(OUTPUT_DIR)/*.pdf 2>/dev/null || echo "  No PDF files found in $(OUTPUT_DIR)/"; \
	else \
		echo "  Output directory does not exist. Run 'make presentation' first."; \
	fi
	@echo ""
	@if [ -d $(SUBMISSIONS_DIR) ]; then \
		echo "Submissions:"; \
		ls -lh $(SUBMISSIONS_DIR)/*.pdf 2>/dev/null || echo "  No submissions found."; \
	fi

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
	@echo "Presentation targets:"
	@echo "  presentation         - Build presentation PDF (no notes)"
	@echo "  presentation-notes   - Build presentation with notes below slides"
	@echo "  presentation-handout - Build handout version (4 slides per page)"
	@echo "  html                 - Build HTML version using Pandoc"
	@echo "  docx                 - Build DOCX version using Pandoc"
	@echo "  view                 - Open presentation PDF in default viewer"
	@echo "  view-presentation    - Open presentation PDF (same as view)"
	@echo "  submissions          - Copy presentation PDF to submissions folder"
	@echo "  submissions-presentation - Copy presentation PDF (same as submissions)"
	@echo ""
	@echo "Utility targets:"
	@echo "  all          - Build all presentation versions (PDF, notes, handout)"
	@echo "  build        - Build PDF, HTML, and DOCX versions"
	@echo "  quick        - Quick single-pass build (no biber, faster iteration)"
	@echo "  watch        - Watch for changes and auto-rebuild"
	@echo "  check        - Show PDF metadata and file info"
	@echo "  lint         - Run LaTeX linter (chktex)"
	@echo "  status       - Show output file information"
	@echo "  clean        - Remove intermediate files"
	@echo "  distclean    - Remove all generated files"
	@echo "  help         - Show this help message"

.PHONY: all presentation presentation-notes presentation-handout html docx view view-presentation submissions submissions-presentation submissions-dir build quick watch check lint status clean distclean help
