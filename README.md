ArchHaskell
===========

The code in this repository builds a binary ArchHaskell repository for
Pacman. As a side-effect, PKGBUILD files for AUR are also generated. At
the heart of the system is the `PKGLIST` file, which determines the set
of Hackage packages to be included in the distribution. Based on this
file, a `GNUmakefile` generates the entire repository offering two
targets:

1. `all`

    Build the entire "habs" tree, but don't  compile binary packages.

2. `world`

    Build everything, including binary packages.

The `world` build phase requires a chroot sandbox that can be created by
running `scripts/setup-chroots`.

Consistency checks of the `PKGLIST` file can be performed as follows:

    # Update the Hackage tarball
    cabal update

    # find inconsistencies
    make scripts/findconflicts
    scripts/findconflicts PKGLIST ~/.cabal/packages/hackage.haskell.org/00-index.tar

    # find updates
    make scripts/findupdates
    scripts/findupdates PKGLIST ~/.cabal/packages/hackage.haskell.org/00-index.tar
