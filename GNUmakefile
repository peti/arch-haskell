# GNUmakefile -- an incremental build of the arch-haskell repository

PKGLIST         := PKGLIST
HABS            := habs
HACKAGE         := hackage
HACKAGE_TARBALL := ~/.cabal/packages/hackage.haskell.org/00-index.tar

GHCFLAGS        := -Wall -O

.PHONY: all world updates publish clean depend
all::

define PACKAGE_template
  $(HACKAGE)/$(2)/$(4)/$(2).cabal : $(HACKAGE)/.extraction-datestamp

  CABALFILES += $(HABS)/$(3)/$(2)-$(4)-$(5).cabal
  $(HABS)/$(3)/$(2)-$(4)-$(5).cabal : $(HACKAGE)/$(2)/$(4)/$(2).cabal
	@mkdir -p $(HABS)/$(3)
	@rm -f $(HABS)/$(3)/$(2)-*.cabal
	@cp -v $$< $$@

  PKGBUILDS += $(HABS)/$(3)/PKGBUILD
  $(HABS)/$(3)/PKGBUILD : $(HABS)/$(3)/$(2)-$(4)-$(5).cabal scripts/cabal2pkgbuild
	@echo 'cabal2pkgbuild $(2)-$(4)-$(5).cabal $(2) $(5)'
	@cd $(HABS)/$(3) && ../../scripts/cabal2pkgbuild $(2)-$(4)-$(5).cabal $(2) $(5)
	@sed -r -i -e "s|^md5sums=.*$$$$|$$$$(cd $(HABS)/$(3) && makepkg 2>/dev/null -mg)|" $(HABS)/$(3)/PKGBUILD

  TAURBALLS += $(HABS)/$(3)/$(3)-$(4)-$(5).src.tar.gz
  $(HABS)/$(3)/$(3)-$(4)-$(5).src.tar.gz : $(HABS)/$(3)/PKGBUILD
	@echo '[GEN]  $(3)-$(4)-$(5).src.tar.gz'
	@cd $(HABS)/$(3) && makepkg >makepkg.log 2>&1 -m --source --force || (cat makepkg.log; false)

  $(HABS)/$(3)/users : scripts/reverse-dependencies $$(PKGBUILDS)
	@echo '[GEN]  $$@'
	@scripts/reverse-dependencies $(HABS) $(3) >$$@
endef

include config.mk

$(foreach pkg,$(PACKAGES),\
  $(eval $(call PACKAGE_template,$(pkg),$($(pkg)_cabalname),$($(pkg)_archname),$($(pkg)_pkgver),$($(pkg)_pkgrel))))

config.mk : $(PKGLIST) scripts/pkglist2mk
	@echo "[GEN]  $@"
	@scripts/pkglist2mk <"$<" >"$@"

all::	$(PKGBUILDS) scripts/find-conflicts
	@scripts/find-conflicts $(CABALFILES)

world::	all scripts/toposort chroot-i686/root/.arch-chroot
	nice -n 20 ./scripts/makeworld

depend::
	@ghc $(GHCFLAGS) -M scripts/*.hs
	@mv Makefile dependencies.mk

chroot-i686/root/.arch-chroot:
	@echo "Please run scripts/setup-chroots to create the chroot environment."
	@false

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

scripts/find-conflicts : scripts/find-conflicts.o Distribution/ArchLinux/HackageTranslation.o
scripts/find-conflicts : Distribution/ArchLinux/SystemProvides.o Distribution/ArchLinux/CabalTranslation.o
scripts/find-conflicts : Distribution/ArchLinux/PkgBuild.o
	@echo "[LINK] $@"
	@ghc $(GHCFLAGS) -package pretty -package Cabal -package tar -package bytestring -o $@ $^

scripts/find-updates : scripts/find-updates.o
	@echo "[LINK] $@"
	@ghc $(GHCFLAGS) -package Cabal -o $@ $^

scripts/reverse-dependencies : scripts/reverse-dependencies.o Distribution/ArchLinux/SrcRepo.o
scripts/reverse-dependencies : Distribution/ArchLinux/PkgBuild.o
	@echo "[LINK] $@"
	@ghc $(GHCFLAGS) -package pretty -package Cabal -o $@ $^

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

updates::	$(HACKAGE)/.extraction-datestamp scripts/find-updates
	@scripts/find-updates $(PKGLIST) $(HACKAGE)

clean::
	@rm -v config.mk dependencies.mk
	@rm -fv scripts/cabal2pkgbuild scripts/find-conflicts scripts/find-updates
	@rm -fv scripts/recdeps scripts/reverse-dependencies scripts/toposort
	@find Distribution '(' -name '*.o' -o -name '*.hi' ')' -print0 | xargs -0 rm -fv
	@find scripts '(' -name '*.o' -o -name '*.hi' ')' -print0 | xargs -0 rm -fv
	@rm -rf $(HABS) $(HACKAGE)
