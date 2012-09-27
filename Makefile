# Makefile for the Neo4j Manual in French.
#
# Note: requires mvn to unpack some stuff first.

# Project Configuration
PROJECTNAME      = manual-french
LANGUAGE         = fr

# Build Configuration
STATIC           = src
ORIGINALSTATIC   = classes
IMPORTED         = docs
TARGET           = target
ORIGINAL         = original
PO               = po
#
BUILDDIR         = $(CURDIR)/$(TARGET)
TOOLSDIR         = $(BUILDDIR)/tools
SRCDIR           = $(CURDIR)
ORIGINALDIR      = $(BUILDDIR)/$(ORIGINAL)
RESOURCEDIR      = $(BUILDDIR)/$(STATIC)
SRCFILE          = $(RESOURCEDIR)/$(PROJECTNAME).asciidoc
IMGDIR           = $(RESOURCEDIR)/images
IMGTARGETDIR     = $(RESOURCEDIR)/images
CSSDIR           = $(TOOLSDIR)/main/resources/css
JSDIR            = $(TOOLSDIR)/main/resources/js
CONFDIR          = $(SRCDIR)/conf
TOOLSCONFDIR     = $(TOOLSDIR)/main/resources/conf
DOCBOOKFILE      = $(BUILDDIR)/$(PROJECTNAME)-shortinfo.xml
DOCBOOKFILEHTML  = $(BUILDDIR)/$(PROJECTNAME)-html.xml
FOPDIR           = $(BUILDDIR)/pdf
FOPFILE          = $(FOPDIR)/$(PROJECTNAME).fo
FOPPDF           = $(FOPDIR)/$(PROJECTNAME).pdf
PARTSMAKE        = $(CURDIR)/parts.make
TEXTWIDTH        = 80
TEXTDIR          = $(BUILDDIR)/text
TEXTFILE         = $(TEXTDIR)/$(PROJECTNAME).txt
TEXTHTMLFILE     = $(TEXTFILE).html
SINGLEHTMLDIR    = $(BUILDDIR)/html
SINGLEHTMLFILE   = $(SINGLEHTMLDIR)/index.html
ANNOTATEDDIR     = $(BUILDDIR)/annotated
ANNOTATEDFILE    = $(HTMLDIR)/$(PROJECTNAME).html
CHUNKEDHTMLDIR   = $(BUILDDIR)/chunked
CHUNKEDOFFLINEHTMLDIR = $(BUILDDIR)/chunked-offline
CHUNKEDTARGET     = $(BUILDDIR)/$(PROJECTNAME).chunked
CHUNKEDSHORTINFOTARGET = $(BUILDDIR)/$(PROJECTNAME)-html.chunked
MANPAGES         = $(BUILDDIR)/manpages
UPGRADE          = $(BUILDDIR)/upgrade
EXTENSIONSRC     = $(TOOLSDIR)/bin/extensions
EXTENSIONDEST    = ~/.asciidoc
SCRIPTDIR        = $(TOOLSDIR)/build
ASCIDOCDIR       = $(TOOLSDIR)/bin/asciidoc
ASCIIDOC         = $(ASCIDOCDIR)/asciidoc.py
A2X              = $(ASCIDOCDIR)/a2x.py
PO4ADIR          = $(TOOLSDIR)/bin/po4a
PO4ALIB          = $(PO4ADIR)/lib
PO4A             = $(PO4ADIR)/po4a
PO4AGETTEXTIZE   = $(PO4ADIR)/po4a-gettextize
PO4ATRANSLATE    = $(PO4ADIR)/po4a-translate
TMPPO            = $(BUILDDIR)/tmp.po
PODIR            = $(CURDIR)/$(PO)

SHELL = /bin/bash


ifdef VERBOSE
	V = -v
	VA = VERBOSE=1
endif

ifdef KEEP
	K = -k
	KA = KEEP=1
endif

ifdef VERSION
	VERSNUM =$(VERSION)
else
	VERSNUM =-neo4j-version
endif

ifdef IMPORTDIR
	IMPDIR = --attribute importdir="$(IMPORTDIR)"
else
	IMPDIR = --attribute importdir="$(BUILDDIR)/$(IMPORTED)"
	IMPORTDIR = "$(BUILDDIR)/$(IMPORTED)"
endif

ifneq (,$(findstring SNAPSHOT,$(VERSNUM)))
	GITVERSNUM =master
else
	GITVERSNUM =$(VERSION)
endif

ifndef VERSION
	GITVERSNUM =master
endif

VERS =  --attribute neo4j-version=$(VERSNUM)

GITVERS = --attribute gitversion=$(GITVERSNUM)

ASCIIDOC_FLAGS = $(V) $(VERS) $(GITVERS) $(IMPDIR)

A2X_FLAGS = $(K) $(ASCIIDOC_FLAGS)

.PHONY: preview help add refresh init

help:
	@echo "Please use 'make <target>' where <target> is one of"
	@echo "  preview     to generate a preview"
	@echo "For verbose output, use 'VERBOSE=1'".
	@echo "To keep temporary files, use 'KEEP=1'".
	@echo "To set the version, use 'VERSION=[the version]'".
	@echo "To set the importdir, use 'IMPORTDIR=[the importdir]'".

#dist: installfilter offline-html html html-check text text-check pdf manpages upgrade cleanup yearcheck

preview: copyoriginal copytranslated refresh simple-asciidoc

init: initialize installextensions

cleanup:
	#
	#
	# Cleaning up.
	#
	#
ifndef KEEP
	rm -f "$(DOCBOOKFILE)"
	rm -f "$(BUILDDIR)/"*.xml
	rm -f "$(ANNOTATEDDIR)/"*.xml
	rm -f "$(FOPDIR)/images"
	rm -f "$(FOPFILE)"
	rm -f "$(UPGRADE)/"*.xml
	rm -f "$(UPGRADE)/"*.html
endif

initialize:
	#
	#
	# Setting correct file permissions and moving source code.
	#
	#
	find $(TOOLSDIR) \( -path '*.py' -o -path '*.sh' \) -exec chmod 0755 {} \;
	find $(PO4ADIR) \( -path '*po4a' -o -path '*po4a-*' \) -exec chmod 0755 {} \;
	if [ -d "$(ORIGINALDIR)/sources/" ]; then \
		rm -rf "$(BUILDDIR)/sources";\
		mv "$(ORIGINALDIR)/sources" "$(BUILDDIR)/sources";\
	fi
	if [ -d "$(ORIGINALDIR)/test-sources/" ]; then \
		rm -rf "$(BUILDDIR)/test-sources";\
		mv "$(ORIGINALDIR)/test-sources" "$(BUILDDIR)/test-sources";\
	fi
	if [ -d "$(ORIGINALDIR)/$(ORIGINALSTATIC)/" ]; then \
		rm -rf "$(ORIGINALDIR)/$(STATIC)";\
		mv "$(ORIGINALDIR)/$(ORIGINALSTATIC)" "$(ORIGINALDIR)/$(STATIC)";\
	fi

installextensions: initialize
	#
	#
	# Installing asciidoc extensions.
	#
	#
	mkdir -p $(EXTENSIONDEST)
	cp -fr "$(EXTENSIONSRC)/"* $(EXTENSIONDEST)

simple-asciidoc: copyoriginal copytranslated refresh
	#
	#
	# Building HTML straight from the AsciiDoc sources.
	#
	#
	mkdir -p "$(SINGLEHTMLDIR)/images"
	mkdir -p "$(SINGLEHTMLDIR)/css"
	mkdir -p "$(SINGLEHTMLDIR)/js"
	"$(ASCIIDOC)" $(ASCIIDOC_FLAGS) --conf-file="$(TOOLSCONFDIR)/asciidoc.conf"  --conf-file="$(CONFDIR)/asciidoc.conf" --attribute docinfo1 --attribute toc --out-file "$(SINGLEHTMLFILE)" "$(SRCFILE)"
	rsync -ru "$(IMGTARGETDIR)/"* "$(SINGLEHTMLDIR)/images"
	rsync -ru "$(CSSDIR)/"* "$(SINGLEHTMLDIR)/css"
	rsync -ru "$(JSDIR)/"* "$(SINGLEHTMLDIR)/js"

copyoriginal:
	#
	# Copy original.
	#
	rsync -ru "$(ORIGINALDIR)/$(STATIC)/"* "$(BUILDDIR)/$(STATIC)"
	rsync -ru "$(ORIGINALDIR)/$(IMPORTED)/"* "$(BUILDDIR)/$(IMPORTED)"

copytranslated:
	#
	# Copy translated documents.
	#
	if [ -d "$(SRCDIR)/$(STATIC)/" ]; then rsync -r "$(SRCDIR)/$(STATIC)/"* "$(BUILDDIR)/$(STATIC)"; fi
	if [ -d "$(SRCDIR)/$(IMPORTED)/" ]; then rsync -r "$(SRCDIR)/$(IMPORTED)/"* "$(BUILDDIR)/$(IMPORTED)"; fi

#
# include the refresh rule.
#
include $(PARTSMAKE)

add:
	#
	# Add a new document to a po file.
	#
	# Note that the translated file has to have the same
	# structure as the original.
	# Usage:
	# make add document="src/introduction/the-neo4j-graphdb.asciidoc" part="introduction"
	#
	if [ -z "$(document)" ]; then echo "Missing parameter 'document'."; exit 1; fi
	if [ -z "$(part)" ]; then echo "Missing parameter 'part'."; exit 1; fi
	$(eval target="$(TARGET)/$(document)")
	$(eval translated="$(document)")
	$(eval original="$(TARGET)/$(ORIGINAL)/$(document)")
	$(eval options=-f text -o asciidoc -L UTF-8 -M UTF-8)
	if [ -f "$(translated)" ]; then \
		PERLLIB=$(PO4ALIB) $(PO4AGETTEXTIZE) $(options) -m $(original) -p "$(TMPPO)" -l $(translated);\
		else \
		PERLLIB=$(PO4ALIB) $(PO4AGETTEXTIZE) $(options) -m $(original) -p "$(TMPPO)";\
	fi
	msginit -i "$(TMPPO)" -o "$(TMPPO)" --locale "$(LANGUAGE)" --no-translator
	touch "$(PODIR)/$(part).po"
	msgcat -o "$(PODIR)/$(part).po" "$(PODIR)/$(part).po" "$(TMPPO)"
	if [ ! -f "$(PODIR)/$(part).conf" ]; then \
		echo "[po4a_paths] $(TARGET)/pot/$(part).pot fr:$(PO)/$(part).po" >> "$(PODIR)/$(part).conf";\
		echo "[po4a_alias: asciidoc] text opt:\"-o asciidoc\"" >> "$(PODIR)/$(part).conf";\
		echo "[options] opt: \"-L UTF-8 -M UTF-8 -A UTF-8\"" >> "$(PODIR)/$(part).conf";\
		echo -e "\t"'PERLLIB=\u0024(PO4ALIB) \u0024(PO4A) -f --keep 0 "'"$(PO)/$(part).conf\"" >> "$(PARTSMAKE)";\
	fi
	echo "[type: asciidoc] $(original) $(LANGUAGE):$(target)" >> "$(PODIR)/$(part).conf"
	# Document was added (if this line is reached)!

