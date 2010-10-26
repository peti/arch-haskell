# GNUmakefile -- an incremental build of the arch-haskell repository

PKGLIST := PKGLIST
HABS	:= habs

.PHONY: all world publish
all world publish clean::

include config.mk

define GEN_PACKAGE_template
 CABALFILES += $$(HABS)/$$($(1)_archname)/$$($(1)_cabalfile)
 $$(HABS)/$$($(1)_archname)/$$($(1)_cabalfile):
	@echo "[WGET] $$($(1)_cabalurl)"
	@mkdir -p $$(HABS)/$$($(1)_archname)
	@wget --quiet --directory-prefix=$$(HABS)/$$($(1)_archname) --no-clobber $$($(1)_cabalurl)
	@mv $$(HABS)/$$($(1)_archname)/$(1).cabal $$@
	@touch $$@

 SRCTARBALLS += $$(HABS)/$$($(1)_archname)/$$($(1)_srctarball)
 $$(HABS)/$$($(1)_archname)/$$($(1)_srctarball):
	@echo "[WGET] $$($(1)_srcurl)"
	@mkdir -p $$(HABS)/$$($(1)_archname)
	@wget --quiet --directory-prefix=$$(HABS)/$$($(1)_archname) --no-clobber $$($(1)_srcurl)

 PKGBUILDS += $$(HABS)/$$($(1)_archname)/PKGBUILD
 $$(HABS)/$$($(1)_archname)/PKGBUILD : $$(HABS)/$$($(1)_archname)/$$($(1)_cabalfile)
 $$(HABS)/$$($(1)_archname)/PKGBUILD : $$(HABS)/$$($(1)_archname)/$$($(1)_srctarball)
 $$(HABS)/$$($(1)_archname)/PKGBUILD : scripts/cabal2pkgbuild
	@echo "[GEN]  $$($(1)_archname)-$$($(1)_version)-$$($(1)_pkgrel)/PKGBUILD"
	@mkdir -p $$(HABS)/$$($(1)_archname)
	@scripts/cabal2pkgbuild $$(HABS)/$$($(1)_archname)/$$($(1)_cabalfile) $$(HABS)/$$($(1)_archname)
	@source $$(HABS)/$$($(1)_archname)/PKGBUILD; [ $$$$pkgname = $$($(1)_archname) ] || \
	  ( echo "*** package name mismatch: $$$$pkgname != $$($(1)_archname)" \
	  ; rm -rfv "$$(HABS)/$$($(1)_archname)" \
	  ; false \
	  )
	@sed -r -i -e 's|^pkgrel=[0-9]+$$$$|pkgrel=$$($(1)_pkgrel)|' $$(HABS)/$$($(1)_archname)/PKGBUILD
	@sed -r -i -e "s|^md5sums=.*$$$$|$$$$(cd $$(HABS)/$$($(1)_archname) && makepkg 2>/dev/null -mg)|" $$(HABS)/$$($(1)_archname)/PKGBUILD

 AURBALLS += $$(HABS)/$$($(1)_archname)/$$($(1)_aurball)
 $$(HABS)/$$($(1)_archname)/$$($(1)_aurball) : $$(HABS)/$$($(1)_archname)/PKGBUILD
	@echo "[GEN]  $$($(1)_aurball)"
	@cd $$(HABS)/$$($(1)_archname) && makepkg >makepkg.log 2>&1 -m --source --force || (cat makepkg.log; false)
endef

$(foreach pkg,$(PACKAGES),$(eval $(call GEN_PACKAGE_template,$(pkg))))

all::	$(AURBALLS)

world::	all scripts/toposort
	./scripts/makeworld

config.mk : $(PKGLIST) scripts/pkglist2mk
	scripts/pkglist2mk <"$<" >"$@"

scripts/% : scripts/%.hs $(wildcard scripts/*.hs) $(shell find Distribution '(' -name '*.hs' -o -name '*.lhs' ')')
	@echo "[GHC]  $@"
	@ghc -o $@ --make -Wall -O $<

publish::
	rsync -vaH chroot-i686/copy/repo/ /usr/local/apache/htdocs/localhost/arch-haskell/

clean::
	@rm -v config.mk
	@rm -fv scripts/cabal2pkgbuild scripts/findconflicts scripts/findupdates
	@rm -fv scripts/recdeps scripts/reverse_deps scripts/toposort
	@find Distribution '(' -name '*.o' -o -name '*.hi' ')' -print0 | xargs -0 rm -fv
	@find scripts '(' -name '*.o' -o -name '*.hi' ')' -print0 | xargs -0 rm -fv
	@rm -rf $(HABS)
