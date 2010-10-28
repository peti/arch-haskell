# GNUmakefile -- an incremental build of the arch-haskell repository

PKGLIST         := PKGLIST
HABS            := habs
HACKAGE         := hackage
HACKAGE_TARBALL := ~/.cabal/packages/hackage.haskell.org/00-index.tar

GHCFLAGS        := -Wall -O

.PHONY: all world publish clean depend
all world publish clean::

include config.mk

define GEN_PACKAGE_template
 $$(HACKAGE)/$(1)/$$($(1)_version)/$(1).cabal : $(HACKAGE)/.extraction-datestamp

 CABALFILES += $$(HABS)/$$($(1)_archname)/$$($(1)_cabalfile)
 $$(HABS)/$$($(1)_archname)/$$($(1)_cabalfile) : $$(HACKAGE)/$(1)/$$($(1)_version)/$(1).cabal
	@echo "[CP]   $$($(1)_cabalfile)"
	@mkdir -p $$(HABS)/$$($(1)_archname)
	@cp $$< $$@

 PKGBUILDS += $$(HABS)/$$($(1)_archname)/PKGBUILD
 $$(HABS)/$$($(1)_archname)/PKGBUILD : $$(HABS)/$$($(1)_archname)/$$($(1)_cabalfile)
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
	@echo "[MD5]  $$($(1)_archname)-$$($(1)_version)-$$($(1)_pkgrel)/PKGBUILD"
	@sed -r -i -e "s|^md5sums=.*$$$$|$$$$(cd $$(HABS)/$$($(1)_archname) && makepkg 2>/dev/null -mg)|" $$(HABS)/$$($(1)_archname)/PKGBUILD

 AURBALLS += $$(HABS)/$$($(1)_archname)/$$($(1)_aurball)
 $$(HABS)/$$($(1)_archname)/$$($(1)_aurball) : $$(HABS)/$$($(1)_archname)/PKGBUILD
	@echo "[GEN]  $$($(1)_aurball)"
	@cd $$(HABS)/$$($(1)_archname) && makepkg >makepkg.log 2>&1 -m --source --force || (cat makepkg.log; false)
endef

$(foreach pkg,$(PACKAGES),$(eval $(call GEN_PACKAGE_template,$(pkg))))

all::	$(PKGBUILDS)

world::	all scripts/toposort
	nice -n 20 ./scripts/makeworld

config.mk : $(PKGLIST) scripts/pkglist2mk
	@echo "[GEN]  $@"
	@scripts/pkglist2mk "$<" >"$@"

depend::
	@echo "[GEN]  dependencies.mk"
	@ghc $(GHCFLAGS) -M scripts/*.hs
	@mv Makefile dependencies.mk

dependencies.mk : depend

include dependencies.mk

scripts/cabal2pkgbuild : scripts/cabal2pkgbuild.o Distribution/ArchLinux/PkgBuild.o
scripts/cabal2pkgbuild : Distribution/ArchLinux/SystemProvides.o
scripts/cabal2pkgbuild : Distribution/ArchLinux/CabalTranslation.o
	@echo "[LINK] $@"
	@ghc $(GHCFLAGS) -package pretty -package Cabal -o $@ $^

scripts/toposort : scripts/toposort.o Distribution/ArchLinux/PkgBuild.o Distribution/ArchLinux/SrcRepo.o
	@echo "[LINK] $@"
	@ghc $(GHCFLAGS) -package pretty -package Cabal -o $@ $^

scripts/findconflicts : scripts/findconflicts.o Distribution/ArchLinux/HackageTranslation.o
scripts/findconflicts : Distribution/ArchLinux/SystemProvides.o Distribution/ArchLinux/CabalTranslation.o
scripts/findconflicts : Distribution/ArchLinux/PkgBuild.o
	@echo "[LINK] $@"
	@ghc $(GHCFLAGS) -package pretty -package Cabal -package bytestring -package tar -o $@ $^

%.o : %.hs
	@echo "[GHC]  $<"
	@ghc $(GHCFLAGS) -o $@ -c $<

%.o : %.lhs
	@echo "[GHC]  $<"
	@ghc $(GHCFLAGS) -o $@ -c $<

%.hi : %.o
	@:

$(HACKAGE_TARBALL):
	@echo ''
	@echo 'Please run "cabal update" to download $(HACKAGE_TARBALL).'
	@echo ''
	@false

$(HACKAGE)/.extraction-datestamp : $(HACKAGE_TARBALL)
	@echo "[TAR]  $<"
	@mkdir -p $(HACKAGE)
	@tar -xf $(HACKAGE_TARBALL) -C $(HACKAGE)
	@date --iso=seconds >$@

publish::
	rsync -vaH chroot-i686/copy/repo/ /usr/local/apache/htdocs/localhost/arch-haskell/

clean::
	@rm -v config.mk dependencies.mk
	@rm -fv scripts/cabal2pkgbuild scripts/findconflicts scripts/findupdates
	@rm -fv scripts/recdeps scripts/reverse_deps scripts/toposort
	@find Distribution '(' -name '*.o' -o -name '*.hi' ')' -print0 | xargs -0 rm -fv
	@find scripts '(' -name '*.o' -o -name '*.hi' ')' -print0 | xargs -0 rm -fv
	@rm -rf $(HABS) $(HACKAGE)
