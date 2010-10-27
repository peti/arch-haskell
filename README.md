ArchHaskell
===========

The code in this repository builds a binary ArchHaskell repository for
Pacman. As a side-effect, PKGBUILD files for AUR are also generated. At
the heart of the system is the `PKGLIST` file, which determines the set
of Hackage packages to be included in the distribution. Based on this
file, a `GNUmakefile` generates the entire repository offering three
targets:

1. `all`

    Build the entire "habs" tree, but don't  compile binary packages.
    This is the default target.

2. `world`

    Build everything, including binary packages.

3. `clean`

    Delete all generated files (except the chroot build sandboxes).

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

This repository is maintained with TopGit. To initialize the various
origins, run the following commands:

    git remote add --no-tags upstream/archlinux git@github.com:archhaskell/archlinux.git
    git config --replace-all remote.upstream/archlinux.fetch master:upstream/archlinux

    git remote add --no-tags upstream/archhaskell-build git://github.com/remyoudompheng/archhaskell-build.git
    git config --replace-all remote.upstream/archhaskell-build.fetch master:upstream/archhaskell-build

    tg remote --populate origin
