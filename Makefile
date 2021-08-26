# Makefile for TTRPG projects ###########################################################################
# By Cadera Spindrift
#
# FOR INTERNAL USE ONLY

# Project Configuration #################################################################################
#
# Project id 
#   Edit: yes
PROJ = clu

# Directories
#   Edit: probably unnecessary
IMGDIR    = ./art
STYLEDIR  = ./style
OUT       = out
OUTDIR    = ./$(OUT)
BINDIR    = ./bin
SRCDIR    = ./src
BUILDDIR  = ./build
BACKDIR   = ./old/backups
DOCSDIR   = ./docs

# Backups
#   Edit: if you want/don't want to back up files when you do make clean
BACKUPS = --backup=numbered
# BACKUPS = -b
# BACKUPS = 

# File Locations
#   Edit: probably unnecessary
PROJ_RECIPE = $(PROJ)
PROJ_SRC    = $(BUILDDIR)/$(PROJ).md
PROJ_OUT    = $(OUTDIR)/Cosmic-Legends.pdf
HTML_OUT    = $(OUTDIR)/$(PROJ).html

PREGEN_RECIPE = pregens
PREGEN_SRC = $(BUILDDIR)/pregens.md
PREGEN_OUT = $(OUTDIR)/Cosmic-Legends-pregens.pdf
SHEET_RECIPE = herosheet
SHEET_SRC = $(BUILDDIR)/herosheet.md
SHEET_OUT = $(OUTDIR)/Cosmic-Legends-herosheet.pdf
SHEET_ALT_OUT = $(OUTDIR)/Cosmic-Legends-herosheet-alt.pdf
SHEET_COLOR_OUT = $(OUTDIR)/Cosmic-Legends-herosheet-colors.pdf

LETTER_OUT = $(OUTDIR)/Cosmic-Legends-letter.pdf

# CSS Location
#   Edit: if you have more than one stylesheet
PROJ_CSS        = --css=$(STYLEDIR)/style.css
PREGEN_CSS      = --css=$(STYLEDIR)/pregens.css
SHEET_CSS       = --css=$(STYLEDIR)/style.css
SHEET_ALT_CSS   = --css=$(STYLEDIR)/alt-sheet.css
SHEET_COLOR_CSS = --css=$(STYLEDIR)/color-sheet.css
LETTER_CSS      = --css=$(STYLEDIR)/letter.css

# Derived Flags
#   Edit: probably unnecessary
FLAGS       = -t html5 --standalone --resource-path=$(IMGDIR) 
PROJ_FLAGS  = $(FLAGS) $(PROJ_CSS) $(PRINCEFLAGS)
PREGEN_FLAGS  = $(FLAGS) $(PREGEN_CSS) $(PRINCEFLAGS_PREGEN)
LETTER_FLAGS  = $(FLAGS) $(LETTER_CSS) $(PRINCEFLAGS_LETTER)
SHEET_FLAGS  = $(FLAGS) $(SHEET_CSS) $(PRINCEFLAGS_SHEET)
SHEET_ALT_FLAGS  = $(FLAGS) $(SHEET_ALT_CSS) $(PRINCEFLAGS_SHEET_ALT)
SHEET_COLOR_FLAGS  = $(FLAGS) $(SHEET_COLOR_CSS) $(PRINCEFLAGS_SHEET_COLOR)

# Application Configruation #############################################################################
#
# Pandoc Config
#   Edit: probably unnecessary
PANDOC         = /usr/bin/pandoc
PANDOCFLAGS    = --variable=date:"$(DATE)" -f $(PANDOC_MD_EXT) --pdf-engine=prince -M document-css=false
PANDOC_MD_EXT  = markdown+pipe_tables+escaped_line_breaks+header_attributes+fancy_lists+startnum+table_captions+link_attributes+fenced_divs+implicit_figures+bracketed_spans+auto_identifiers

# Prince Config
#   Edit: Sure, if you need to
# PRINCEFLAGS    = --pdf-engine-opt=--css-dpi=300
PRINCEFLAGS    = 
PRINCEFLAGS_PREGEN = 
PRINCEFLAGS_LETTER    = 
PRINCEFLAGS_SHEET    = 
PRINCEFLAGS_SHEET_ALT    = 
PRINCEFLAGS_SHEET_COLOR    = 
# PRINCEFLAGS             = --pdf-engine-opt=--raster-output=$(OUTDIR)/pages/page_%d.png
# PRINCEFLAGS_PREGEN      = --pdf-engine-opt=--raster-output=$(OUTDIR)/pages/pregen_%d.png
# PRINCEFLAGS_LETTER      = --pdf-engine-opt=--raster-output=$(OUTDIR)/pages/letter_%d.png
# PRINCEFLAGS_SHEET       = --pdf-engine-opt=--raster-output=$(OUTDIR)/pages/herosheet_%d.png
# PRINCEFLAGS_SHEET_ALT   = --pdf-engine-opt=--raster-output=$(OUTDIR)/pages/herosheet_alt_%d.png
# PRINCEFLAGS_SHEET_COLOR = --pdf-engine-opt=--raster-output=$(OUTDIR)/pages/herosheet_color_%d.png

# Pdfinfo Config
#   Edit: probably unnecessary
PDFINFO        = /usr/bin/pdfinfo
PDFINFO_GREP   = | /bin/grep -v "no"

# Make Markdown Script Config
#   Edit: you can turn off quiet mode
MAKE_MD = $(BINDIR)/make-markdown.lua -q
# MAKE_MD = $(BINDIR)/make-markdown.lua

# Editor Config (for make edit)
EDITOR = /usr/bin/vim

# Open Windows File Explorer
#   Edit: if you want to open the directory
# EXPLORER = /mnt/c/WINDOWS/explorer.exe $(OUT)
EXPLORER = 

# Variables #############################################################################################
#
# Date Variable
#   Edit: no
DATE           = $(shell date '+%Y-%b-%d %H:%M %z')

# Color variables
#   Edit: no

dkblck := $(shell tput setaf 0)
dkredd := $(shell tput setaf 1)
dkgren := $(shell tput setaf 2)
dkyelo := $(shell tput setaf 3)
dkblue := $(shell tput setaf 4)
dkmagn := $(shell tput setaf 5)
dkcyan := $(shell tput setaf 6)
dkwhit := $(shell tput setaf 7)
dkorng := $(shell tput setaf 166)
ltgray := $(shell tput setaf 8)
ltredd := $(shell tput setaf 9)
ltgren := $(shell tput setaf 10)
ltyelo := $(shell tput setaf 11)
ltblue := $(shell tput setaf 12)
ltmagn := $(shell tput setaf 13)
ltcyan := $(shell tput setaf 14)
ltwhit := $(shell tput setaf 15)
ltorng := $(shell tput setaf 208)
resetc := $(shell tput sgr0)

bgblck := $(shell tput setab 0)
bgredd := $(shell tput setab 1)
bggren := $(shell tput setab 2)
bgyelo := $(shell tput setab 3)
bgblue := $(shell tput setab 4)
bgmagn := $(shell tput setab 5)
bgcyan := $(shell tput setab 6)
bgwhit := $(shell tput setab 7)
bgorng := $(shell tput setab 166)
blgray := $(shell tput setab 8)
blredd := $(shell tput setab 9)
blgren := $(shell tput setab 10)
blyelo := $(shell tput setab 11)
blblue := $(shell tput setab 12)
blmagn := $(shell tput setab 13)
blcyan := $(shell tput setab 14)
blwhit := $(shell tput setab 15)
blorng := $(shell tput setab 208)

# Default Make Script ###################################################################################
#   Edit: if you want to change the default, e.g. to make testing easier
# default: help
# default: pregen
default: pdf
# default: all
# default: sheet

# Make Help #############################################################################################
#
# make help
#  Edit: if you add additional make options e.g. another pdf to make
help:
	@ echo   '$(dkcyan)make$(resetc) arguments:'
	@ echo '  $(dkcyan)make$(resetc) $(ltmagn)markdown   $(resetc)- collect markdown'
	@ echo '  $(dkcyan)make$(resetc) $(ltblue)pdf        $(resetc)- create pdf'
	@ echo '  $(dkcyan)make$(resetc) $(ltcyan)html       $(resetc)- create html'
	@ echo '  $(dkcyan)make$(resetc) $(ltgren)all        $(resetc)- create markdown, pdf, html'
	@ echo '  $(dkcyan)make$(resetc) $(ltyelo)clean      $(resetc)- clean $(OUTDIR), $(BUILDDIR); makes backups'
	@ echo '  $(dkcyan)make$(resetc) $(ltorng)backups    $(resetc)- back up $(OUTDIR), $(BUILDDIR)'
	@ echo '  $(dkcyan)make$(resetc) $(dkredd)purge      $(resetc)- $(dkredd)purge$(resetc) $(OUTDIR), $(BUILDDIR), $(BACKDIR)'
	@ echo '  $(dkcyan)make$(resetc) $(dkmagn)edit       $(resetc)- edit the Makefile in $(EDITOR)'
	@ echo '  $(dkcyan)make$(resetc) $(dkblue)ls         $(resetc)- recursive ls'

# Various Make Utilities ################################################################################
#
# make edit
#  Edit: no
edit:
	@ $(EDITOR) Makefile

# make backups
#   Edit: no
backups:
	@ echo '$(ltorng)Backup up $(OUTDIR) and $(BUILDDIR).$(resetc)'
	@ -cp   $(BACKUPS) $(OUTDIR)/* $(BUILDDIR)/* $(BACKDIR)
	@ rm    $(BACKDIR)/README*
	@ cp    $(DOCSDIR)/README_BACKUPS.md $(BACKDIR)
	@ echo '$(ltorng)Copied to $(BACKDIR).$(resetc)'

# make clean
#   Edit: no
clean:
	@ echo '$(ltyelo)Cleaning $(OUTDIR) and $(BUILDDIR).$(resetc)'
	@ -mv   $(BACKUPS) $(OUTDIR)/* $(BUILDDIR)/* $(BACKDIR)
	@ cp    $(DOCSDIR)/README_OUT.md     $(OUTDIR)
	@ cp    $(DOCSDIR)/README_BUILD.md   $(BUILDDIR)
	@ rm    $(BACKDIR)/README*
	@ cp    $(DOCSDIR)/README_BACKUPS.md $(BACKDIR)
	@ echo '$(ltyelo)Moved to $(BACKDIR).$(resetc)'

# make purge
#  Edit: no
purge:
	@ echo '$(dkredd)Purging$(resetc) $(OUTDIR) $(BUILDDIR) and $(BACKDIR).'
	@ -rm   $(BACKDIR)/* $(BUILDDIR)/* $(OUTDIR)/*
	@ cp    $(DOCSDIR)/README_OUT.md     $(OUTDIR)
	@ cp    $(DOCSDIR)/README_BUILD.md   $(BUILDDIR)
	@ cp    $(DOCSDIR)/README_BACKUPS.md $(BACKDIR)
	@ echo '$(dkredd)Purged.$(resetc)'

# make ls
#   Edit: no
ls: ls-src ls-build ls-out ls-back

ls-src:
	@ echo -n '$(resetc)'
	@ /bin/ls -R --color $(SRCDIR)
	@ echo '$(resetc)'

ls-build:
	@ echo '$(resetc)$(blmagn)$(dkblck)$(BUILDDIR)'
	@ /bin/ls --color=never $(BUILDDIR)
	@ echo '$(resetc)'

ls-out:
	@ echo '$(resetc)$(blgren)$(dkblck)$(OUTDIR)'
	@ /bin/ls --color=never $(OUTDIR)
	@ echo '$(resetc)'

ls-back:
	@ echo '$(resetc)$(blorng)$(dkblck)$(BACKDIR)'
	@ /bin/ls --color=never $(BACKDIR)
	@ echo '$(resetc)'

# Actual Make Scripts ###################################################################################
#
# make markdown
#   Edit: if you are making multiple docs
markdown:
	@ echo '$(ltmagn)Collecting markdown.$(resetc)'
	@       $(MAKE_MD) $(PROJ_RECIPE)

# make pdf
#   Edit: if you are making more than one pdf
pdf: markdown
	@ echo '$(ltblue)Making PDF.$(resetc)'
	@       $(PANDOC) $(PANDOCFLAGS) $(PROJ_FLAGS) -o $(PROJ_OUT) $(PROJ_SRC)
	@       $(PDFINFO) $(PROJ_OUT) $(PDFINFO_GREP)
	@      -$(EXPLORER)

letter: markdown
	@ echo '$(ltblue)Making Letter PDF.$(resetc)'
	@       $(PANDOC) $(PANDOCFLAGS) $(LETTER_FLAGS) -o $(LETTER_OUT) $(PROJ_SRC)
	@       $(PDFINFO) $(LETTER_OUT) $(PDFINFO_GREP)
	@      -$(EXPLORER)

sheet-markdown:
	@ echo '$(ltmagn)Collecting sheet markdown.$(resetc)'
	@       $(MAKE_MD) $(SHEET_RECIPE)

pregen-markdown:
	@ echo '$(ltmagn)Collecting pregen markdown.$(resetc)'
	@       $(MAKE_MD) $(PREGEN_RECIPE)

pregen: pregen-markdown
	@ echo '$(ltblue)Making Pregens.$(resetc)'
	@       $(PANDOC) $(PANDOCFLAGS) $(PREGEN_FLAGS) -o $(PREGEN_OUT) $(PREGEN_SRC)
	@       $(PDFINFO) $(PREGEN_OUT) $(PDFINFO_GREP)
	@      -$(EXPLORER)

sheet: sheet-markdown
	@ echo '$(ltblue)Making Hero Sheet.$(resetc)'
	@       $(PANDOC) $(PANDOCFLAGS) $(SHEET_FLAGS) -o $(SHEET_OUT) $(SHEET_SRC)
	@       $(PDFINFO) $(SHEET_OUT) $(PDFINFO_GREP)
	@      -$(EXPLORER)

alt-sheet: sheet-markdown
	@ echo '$(ltblue)Making Alternate Hero Sheet.$(resetc)'
	@       $(PANDOC) $(PANDOCFLAGS) $(SHEET_ALT_FLAGS) -o $(SHEET_ALT_OUT) $(SHEET_SRC)
	@       $(PDFINFO) $(SHEET_ALT_OUT) $(PDFINFO_GREP)
	@      -$(EXPLORER)

color-sheet: sheet-markdown
	@ echo '$(ltblue)Making Colorful Hero Sheet.$(resetc)'
	@       $(PANDOC) $(PANDOCFLAGS) $(SHEET_COLOR_FLAGS) -o $(SHEET_COLOR_OUT) $(SHEET_SRC)
	@       $(PDFINFO) $(SHEET_COLOR_OUT) $(PDFINFO_GREP)
	@      -$(EXPLORER)


# make HTML
#   Edit: if you are making more than one html
html: markdown
	@ echo '$(ltcyan)Making HTML.$(resetc)'
	@       $(PANDOC) $(PANDOCFLAGS) $(FLAGS) -o $(HTML_OUT) $(PROJ_SRC)
	@ echo '$(ltcyan)HTML built.$(resetc)'
	@       $(EDITOR) $(HTML_OUT)

# make all
#   Edit: if you are making more than one pdf or html
all: pdf letter sheets pregen
sheets: sheet alt-sheet color-sheet 

# Make Aliases ##########################################################################################
#  Edit: only you if want to add something
md:     markdown
game:   pdf letter
backup: backups
vi:     edit
vim:    edit
sheet-alt: alt-sheet
pregens: pregen
