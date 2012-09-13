# Makefile for the Neo4j Manual in French.
#
# Note: requires mvn to unpack some stuff first.

PROJECTNAME      = manual-french
LANGUAGE         = fr
BUILDDIR         = $(CURDIR)/target
TOOLSDIR         = $(BUILDDIR)/tools
SRCDIR           = $(CURDIR)
RESOURCEDIR      = $(BUILDDIR)/classes
SRCFILE          = $(SRCDIR)/$(PROJECTNAME).asciidoc
IMGDIR           = $(SRCDIR)/images
IMGTARGETDIR     = $(BUILDDIR)/classes/images
CSSDIR           = $(TOOLSDIR)/main/resources/css
JSDIR            = $(TOOLSDIR)/main/resources/js
CONFDIR          = $(SRCDIR)/conf
TOOLSCONFDIR     = $(TOOLSDIR)/main/resources/conf
DOCBOOKFILE      = $(BUILDDIR)/$(PROJECTNAME)-shortinfo.xml
DOCBOOKFILEHTML  = $(BUILDDIR)/$(PROJECTNAME)-html.xml
FOPDIR           = $(BUILDDIR)/pdf
FOPFILE          = $(FOPDIR)/$(PROJECTNAME).fo
FOPPDF           = $(FOPDIR)/$(PROJECTNAME).pdf
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
PODIR            = $(CURDIR)/po


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
	IMPDIR = --attribute importdir="$(BUILDDIR)/docs"
	IMPORTDIR = "$(BUILDDIR)/docs"
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

.PHONY: preview help translate gettextize

help:
	@echo "Please use 'make <target>' where <target> is one of"
	@echo "  preview     to generate a preview"
	@echo "For verbose output, use 'VERBOSE=1'".
	@echo "To keep temporary files, use 'KEEP=1'".
	@echo "To set the version, use 'VERSION=[the version]'".
	@echo "To set the importdir, use 'IMPORTDIR=[the importdir]'".

#dist: installfilter offline-html html html-check text text-check pdf manpages upgrade cleanup yearcheck

preview: initialize installextensions simple-asciidoc

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
	# Setting correct file permissions.
	#
	#
	find $(TOOLSDIR) \( -path '*.py' -o -path '*.sh' \) -exec chmod 0755 {} \;
	find $(PO4ADIR) \( -path '*po4a' -o -path '*po4a-*' \) -exec chmod 0755 {} \;

installextensions: initialize
	#
	#
	# Installing asciidoc extensions.
	#
	#
	mkdir -p $(EXTENSIONDEST)
	cp -fr "$(EXTENSIONSRC)/"* $(EXTENSIONDEST)

simple-asciidoc: initialize installextensions
	#
	#
	# Building HTML straight from the AsciiDoc sources.
	#
	#
	mkdir -p "$(SINGLEHTMLDIR)/images"
	mkdir -p "$(SINGLEHTMLDIR)/css"
	mkdir -p "$(SINGLEHTMLDIR)/js"
	"$(ASCIIDOC)" $(ASCIIDOC_FLAGS) --conf-file="$(TOOLSCONFDIR)/asciidoc.conf"  --conf-file="$(CONFDIR)/asciidoc.conf" --attribute docinfo1 --attribute toc --out-file "$(SINGLEHTMLFILE)" "$(SRCFILE)"
	cp -ru "$(IMGTARGETDIR)/"* "$(SINGLEHTMLDIR)/images"
	cp -ru "$(CSSDIR)/"* "$(SINGLEHTMLDIR)/css"
	cp -ru "$(JSDIR)/"* "$(SINGLEHTMLDIR)/js"

translate:
	# running po4a
	PERLLIB=$(PO4ALIB) $(PO4ATRANSLATE)  -f text -m target/classes/introduction/the-neo4j-graphdb.txt -p po/introduction.po -l target/generated/introduction/the-neo4j-graphdb.asciidoc -o asciidoc -L UTF-8 -M UTF-8

gettextize:
	if [ -z "$(original)" ]; then echo "Missing parameter 'original'."; exit 1; fi
	if [ -z "$(translation)" ]; then echo "Missing parameter 'translation'."; exit 1; fi
	if [ -z "$(part)" ]; then echo "Missing parameter 'part'."; exit 1; fi
	if [ -z "$(target)" ]; then echo "Missing parameter 'target'."; exit 1; fi
	PERLLIB=$(PO4ALIB) $(PO4AGETTEXTIZE) -f text -m "$(original)" -l "$(translation)" -p "$(TMPPO)" -o asciidoc -L UTF-8 -M UTF-8
	msginit -i "$(TMPPO)" -o "$(TMPPO)" --locale "$(LANGUAGE)" --no-translator
	touch "$(PODIR)/$(part).po"
	msgcat -o "$(PODIR)/$(part).po" "$(PODIR)/$(part).po" "$(TMPPO)"
	echo "[type: asciidoc] $(original) $(LANGUAGE):$(target)" >> "$(PODIR)/$(part).conf"
	#make gettextize original="target/classes/introduction/the-neo4j-graphdb.txt" translation="introduction/the-neo4j-graphdb.asciidoc" part="introduction" target="target/generated/introduction/the-neo4j-graphdb.asciidoc"


