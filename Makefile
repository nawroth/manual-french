# Makefile for the Neo4j Manual in French.
#
# Note: requires mvn to unpack some stuff first.

# Project Configuration
project_name               = manual-french
language                   = fr

# Names
main_source                = src
legacy_main_source         = classes
imported_source            = docs
target                     = target
original                   = original
po                         = po
# Source Directories
source_dir                 = $(CURDIR)
config_dir                 = $(source_dir)/conf
build_dir                  = $(CURDIR)/$(target)
build_source_dir           = $(build_dir)/$(main_source)
build_image_dir            = $(build_source_dir)/images
original_dir               = $(build_dir)/$(original)
tools_dir                  = $(build_dir)/tools
tools_config_dir           = $(tools_dir)/main/resources/conf
tools_css_dir              = $(tools_dir)/main/resources/css
tools_js_dir               = $(tools_dir)/main/resources/js
extensions_source_dir      = $(tools_dir)/bin/extensions
script_dir                 = $(tools_dir)/build
asciidoc_dir               = $(tools_dir)/bin/asciidoc
po4a_dir                   = $(tools_dir)/bin/po4a
po4a_lib_dir               = $(po4a_dir)/lib
po_dir                     = $(CURDIR)/$(po)
make_dir                   = $(tools_dir)/make
# Commands
asciidoc                   = $(asciidoc_dir)/asciidoc.py
a2x                        = $(asciidoc_dir)/a2x.py
po4a                       = $(po4a_dir)/po4a
po4a_gettextize            = $(po4a_dir)/po4a-gettextize
# Destination directories
extensions_destination_dir = ~/.asciidoc
#
source_document            = $(build_source_dir)/$(project_name).asciidoc
#
docbook_file               = $(build_dir)/$(project_name)-shortinfo.xml
docbook_file_html          = $(build_dir)/$(project_name)-html.xml
#
fop_dir                    = $(build_dir)/pdf
fop_file                   = $(fop_dir)/$(project_name).fo
fop_pdf                    = $(fop_dir)/$(project_name).pdf
#
text_max_width             = 80
text_dir                   = $(build_dir)/text
text_file                  = $(text_dir)/$(project_name).txt
text_html_file             = $(text_file).html
#
single_html_dir            = $(build_dir)/html
single_html_file           = $(single_html_dir)/index.html
#
annotated_dir              = $(build_dir)/annotated
annotated_file             = $(annotated_dir)/index.html
#
chunked_html_dir           = $(build_dir)/chunked
chunked_offline_html_dir   = $(build_dir)/chunked-offline
chunked_target             = $(build_dir)/$(project_name).chunked
chunked_short_info_target  = $(build_dir)/$(project_name)-html.chunked
#
manpages_dir               = $(build_dir)/manpages
upgrade_dir                = $(build_dir)/upgrade
#
#
make_parts                 = $(CURDIR)/parts.make
tmp_po                     = $(build_dir)/tmp.po

SHELL = /bin/bash

#include $(make_dir)/flags.make


ifdef VERBOSE
	verbose_flag = -v
endif

ifdef KEEP
	keep_flag = -k
endif

ifdef VERSION
	version_number =$(VERSION)
else
	version_number =-neo4j-version
endif

ifdef IMPORTDIR
	import_dir_attribute = --attribute importdir="$(IMPORTDIR)"
else
	import_dir_attribute = --attribute importdir="$(build_dir)/$(imported_source)"
	IMPORTDIR = "$(build_dir)/$(imported_source)"
endif

ifneq (,$(findstring SNAPSHOT,$(version_number)))
	git_version_number =master
else
	git_version_number =$(verbose_flagERSION)
endif

ifndef VERSION
	git_version_number =master
endif

version_attribute =  --attribute neo4j-version=$(version_number)

git_version_attribute = --attribute gitversion=$(git_version_number)

asciidoc_flags = $(verbose_flag) $(version_attribute) $(git_version_attribute) $(import_dir_attribute)

a2x_flags = $(keep_flag) $(asciidoc_flags)


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
	rm -f "$(docbook_file)"
	rm -f "$(build_dir)/"*.xml
	rm -f "$(annotated_dir)/"*.xml
	rm -f "$(fop_dir)/images"
	rm -f "$(fop_file)"
	rm -f "$(upgrade_dir)/"*.xml
	rm -f "$(upgrade_dir)/"*.html
endif

initialize:
	#
	#
	# Setting correct file permissions and moving source code.
	#
	#
	find $(tools_dir) \( -path '*.py' -o -path '*.sh' \) -exec chmod 0755 {} \;
	find $(po4a_dir) \( -path '*po4a' -o -path '*po4a-*' \) -exec chmod 0755 {} \;
	if [ -d "$(original_dir)/sources/" ]; then \
		rm -rf "$(build_dir)/sources";\
		mv "$(original_dir)/sources" "$(build_dir)/sources";\
	fi
	if [ -d "$(original_dir)/test-sources/" ]; then \
		rm -rf "$(build_dir)/test-sources";\
		mv "$(original_dir)/test-sources" "$(build_dir)/test-sources";\
	fi
	if [ -d "$(original_dir)/$(legacy_main_source)/" ]; then \
		rm -rf "$(original_dir)/$(main_source)";\
		mv "$(original_dir)/$(legacy_main_source)" "$(original_dir)/$(main_source)";\
	fi

installextensions: initialize
	#
	#
	# Installing asciidoc extensions.
	#
	#
	mkdir -p $(extensions_destination_dir)
	cp -fr "$(extensions_source_dir)/"* $(extensions_destination_dir)

simple-asciidoc: copyoriginal copytranslated refresh
	#
	#
	# Building HTML straight from the AsciiDoc sources.
	#
	#
	mkdir -p "$(single_html_dir)/images"
	mkdir -p "$(single_html_dir)/css"
	mkdir -p "$(single_html_dir)/js"
	"$(asciidoc)" $(asciidoc_flags) --conf-file="$(tools_config_dir)/asciidoc.conf"  --conf-file="$(config_dir)/asciidoc.conf" --attribute docinfo1 --attribute toc --out-file "$(single_html_file)" "$(source_document)"
	rsync -ru "$(build_image_dir)/"* "$(single_html_dir)/images"
	rsync -ru "$(tools_css_dir)/"* "$(single_html_dir)/css"
	rsync -ru "$(tools_js_dir)/"* "$(single_html_dir)/js"

copyoriginal:
	#
	# Copy original.
	#
	rsync -ru "$(original_dir)/$(main_source)/"* "$(build_dir)/$(main_source)"
	rsync -ru "$(original_dir)/$(imported_source)/"* "$(build_dir)/$(imported_source)"

copytranslated:
	#
	# Copy translated documents.
	#
	if [ -d "$(source_dir)/$(main_source)/" ]; then rsync -r "$(source_dir)/$(main_source)/"* "$(build_dir)/$(main_source)"; fi
	if [ -d "$(source_dir)/$(imported_source)/" ]; then rsync -r "$(source_dir)/$(imported_source)/"* "$(build_dir)/$(imported_source)"; fi

#
# include the refresh rule.
#
include $(make_parts)

add:
	#
	# Add a new document to a po file.
	#
	# Note that the translated file has to have the same
	# structure as the original.
	# Usage:
	# make add DOCUMENT="src/introduction/the-neo4j-graphdb.asciidoc" PART="introduction"
	#
	if [ -z "$(DOCUMENT)" ]; then echo "Missing parameter 'DOCUMENT'."; exit 1; fi
	if [ -z "$(PART))" ]; then echo "Missing parameter 'PART'."; exit 1; fi
	$(eval target_document="$(target)/$(DOCUMENT)")
	$(eval translated="$(DOCUMENT)")
	$(eval original="$(target)/$(original)/$(DOCUMENT)")
	$(eval options=-f text -o asciidoc -L UTF-8 -M UTF-8)
	if [ -f "$(translated)" ]; then \
		PERLLIB=$(po4a_lib_dir) $(po4a_gettextize) $(options) -m $(original) -p "$(tmp_po)" -l $(translated);\
		else \
		PERLLIB=$(po4a_lib_dir) $(po4a_gettextize) $(options) -m $(original) -p "$(tmp_po)";\
	fi
	msginit -i "$(tmp_po)" -o "$(tmp_po)" --locale "$(language)" --no-translator
	touch "$(po_dir)/$(PART).po"
	msgcat -o "$(po_dir)/$(PART).po" "$(po_dir)/$(PART).po" "$(tmp_po)"
	if [ ! -f "$(po_dir)/$(PART).conf" ]; then \
		echo "[po4a_paths] $(target)/pot/$(PART).pot fr:$(po)/$(PART).po" >> "$(po_dir)/$(PART).conf";\
		echo "[po4a_alias: asciidoc] text opt:\"-o asciidoc\"" >> "$(po_dir)/$(PART).conf";\
		echo "[options] opt: \"-L UTF-8 -M UTF-8 -A UTF-8\"" >> "$(po_dir)/$(PART).conf";\
		echo -e "\t"'PERLLIB=\u0024(po4a_lib_dir) \u0024(po4a) -f --keep 0 "'"$(po)/$(PART).conf\"" >> "$(make_parts)";\
	fi
	echo "[type: asciidoc] $(original) $(language):$(target_document)" >> "$(po_dir)/$(PART).conf"
	# Document was added (if this line is reached)!

