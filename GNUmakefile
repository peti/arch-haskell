# GNUmakefile -- an incremental build of the arch-haskell repository

PKGLIST         := PKGLIST
HABS            := habs
HACKAGE         := hackage
HACKAGE_TARBALL := ~/.cabal/packages/hackage.haskell.org/00-index.tar

GHCFLAGS        := -Wall -O

.PHONY: all world publish clean depend
all world publish clean::

include config.mk

config.mk : $(PKGLIST) scripts/pkglist2mk
	@echo "[GEN]  $@"
	@scripts/pkglist2mk <"$<" >"$@"

all::	$(PKGBUILDS)

world::	all scripts/toposort
	nice -n 20 ./scripts/makeworld

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
