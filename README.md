ArchHaskell
===========

The code in this repository builds a binary ArchHaskell repository for
Pacman. As a side-effect, PKGBUILD files for AUR are also generated. At
the heart of the system is the `PKGLIST` file, which determines the set
of Hackage packages to be included in the distribution. Based on this
file, a `GNUmakefile` generates the entire repository offering four
targets:

1. `all`

    Build the entire "habs" tree and perform some basic consistency
    checks. This is the default target.

2. `world`

    This target implicitly runs `all`, and then build all binary
    packages. That procedure requires a chroot sandbox, which can be
    created by running the script `scripts/setup-chroots`.

3. `updates`

    Find all available updates in the current Hackage database. Only
    packages mentioned in `PKGLIST` are considered. The hackage database
    should be updated first by running `cabal update`.

4. `clean`

    Delete all generated files (except the chroot build sandboxes).
