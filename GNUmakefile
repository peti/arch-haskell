# GNUmakefile -- an incremental build of the arch-haskell repository

PKGLIST         := PKGLIST
HABS            := habs
HACKAGE         := hackage
HACKAGE_TARBALL := ~/.cabal/packages/hackage.haskell.org/00-index.tar
ARCH		:= $(shell uname -m)
CHROOT		:= /var/tmp/chroot-$(ARCH)

GHCFLAGS        := -Wall -O -i.

.PHONY: all world updates src publish clean depend
all::

include config.mk

config.mk : $(PKGLIST) scripts/pkglist2mk
	@echo "[GEN]  $@"
	@scripts/pkglist2mk <"$<" >"$@"

all::	$(PKGBUILDS) scripts/find-conflicts
	@scripts/find-conflicts $(CABALFILES)

world::	all
	nice -n 20 ./makeworld $(HABS)

src::	$(TAURBALLS)

depend::
	@ghc $(GHCFLAGS) -M scripts/*.hs
	@mv Makefile dependencies.mk

dependencies.mk : depend

include dependencies.mk

scripts/cabal2pkgbuild : scripts/cabal2pkgbuild.o Distribution/ArchLinux/PkgBuild.o
scripts/cabal2pkgbuild : Distribution/ArchLinux/SystemProvides.o
scripts/cabal2pkgbuild : Distribution/ArchLinux/CabalTranslation.o
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
	@sudo ln -s -f repo.db $(CHROOT)/copy/repo/haskell.db
	@sudo ln -s -f repo.db.tar.gz $(CHROOT)/copy/repo/haskell.db.tar.gz
	rsync -vaHP $(CHROOT)/copy/repo/ andromeda.kiwilight.com:/srv/haskell/$(ARCH)/

updates::	$(HACKAGE)/.extraction-datestamp scripts/find-updates
	@scripts/find-updates $(PKGLIST) $(HACKAGE)

clean::
	@rm -v config.mk dependencies.mk
	@rm -fv scripts/cabal2pkgbuild scripts/find-conflicts scripts/find-updates
	@rm -fv scripts/recdeps scripts/reverse-dependencies
	@find Distribution '(' -name '*.o' -o -name '*.hi' ')' -print0 | xargs -0 rm -fv
	@find scripts '(' -name '*.o' -o -name '*.hi' ')' -print0 | xargs -0 rm -fv
	@rm -rf $(HABS) $(HACKAGE)
