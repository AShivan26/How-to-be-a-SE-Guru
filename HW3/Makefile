DATA   = page_blocks_dirty.csv
OUTDIR = out
AWK    = $(shell command -v gawk 2>/dev/null || command -v awk 2>/dev/null || echo awk)

PART1 = $(OUTDIR)/S1 $(OUTDIR)/S2 $(OUTDIR)/S3 $(OUTDIR)/S4 $(OUTDIR)/S5

.PHONY: all clean sh date files help push

# ── Help (default) ───────────────────────────────────
help:
	@echo "make"; \
	echo ""; \
	echo "Usage:"; \
	echo "  make <target>"; \
	echo ""; \
	echo "targets:"; \
	echo "  date             show date"; \
	echo "  files            show files"; \
	echo "  help             show help."; \
	echo "  sh               run my shell"

all: $(PART1)

date:
	@date

files:
	@ls -la

push: 
	@read -p "Reason? " msg; git commit -am "$$msg"; git push; git status

sh:
	@echo " _|_ |_  o ._  |    _|_    _|  _  "; \
	echo "  |_ | | | | | |<    |    (_| (_) "; \
	echo ""; \
	bash -c ' \
	export BASH_SILENCE_DEPRECATION_WARNING=1; \
	if command -v tput >/dev/null 2>&1; then \
		bold=$$(tput bold); col0=$$(tput sgr0); col1=$$(tput setaf 6); col2=$$(tput setaf 3); \
	else \
		bold="\033[1m"; col0="\033[0m"; col1="\033[36m"; col2="\033[33m"; \
	fi; \
	export bold col0 col1 col2; \
	_prompt() { \
		p=$$(basename "$$(dirname "$$PWD")"); \
		d=$$(basename "$$PWD"); \
		b="main*"; \
		git rev-parse --git-dir >/dev/null 2>&1 && b=$$(git branch --show-current 2>/dev/null || echo "main") && [ -n "$$(git status --porcelain 2>/dev/null)" ] && b="$${b}*"; \
		PS1="\[$${col1}\]🔆 $${p}/$${d} \[$${col2}\]$${b}\[$${col0}\] \[$${bold}\]▶\[$${col0}\] "; \
	}; \
	export -f _prompt; \
	export PROMPT_COMMAND="_prompt"; \
	_prompt; \
	exec bash'

$(HOME)/tmp/%.html: %.py
	@mkdir -p $(HOME)/tmp; \
	pycco -d $(HOME)/tmp $<; \
	echo '.docs p, .docs h1, .docs h2, .docs li { text-align: right !important }' >> $(HOME)/tmp/pycco.css


$(OUTDIR)/S1: $(DATA)
	mkdir -p $(OUTDIR); $(AWK) -f S1.awk $< > $@

$(OUTDIR)/S2: $(DATA)
	mkdir -p $(OUTDIR); $(AWK) -f S2.awk $< > $@

$(OUTDIR)/S3: $(DATA)
	mkdir -p $(OUTDIR); $(AWK) -f S3.awk $< > $@

$(OUTDIR)/S4: $(DATA)
	mkdir -p $(OUTDIR); $(AWK) -f S4.awk $< > $@ 2>&1

$(OUTDIR)/S5: $(DATA)
	mkdir -p $(OUTDIR); $(AWK) -f S5.awk $< > $@


clean:
	rm -rf $(OUTDIR)

