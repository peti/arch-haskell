module Main ( main ) where

-- package: Cabal
import Distribution.PackageDescription.Parse ( readPackageDescription )
import Distribution.Verbosity ( normal )

-- package: archlinux
import Distribution.ArchLinux.PkgBuild ( pkg2doc, arch_pkgname, pkgBody )
import Distribution.ArchLinux.CabalTranslation ( preprocessCabal, cabal2pkg, install_hook_name )
import Distribution.ArchLinux.SystemProvides ( getSystemProvidesFromFiles )

-- package: base
import Text.PrettyPrint ( render )
import System.Environment ( getArgs )

main :: IO ()
main = do
  cabalFile:archname:release:[] <- getArgs
  let email = "Arch Haskell Team <arch-haskell@haskell.org>"
  cabalSrc <- readPackageDescription normal cabalFile
  systemPkgs <- getSystemProvidesFromFiles "../../data/ghc-provides.txt" "../../data/library-providers.txt"
  case preprocessCabal cabalSrc systemPkgs of
    Nothing -> fail ("cannot parse and/or resolve " ++ show cabalFile)
    Just cabalPkg -> do
      let (pkgbuild, hooks) = cabal2pkg cabalPkg archname (read release) systemPkgs
      writeFile "PKGBUILD" (render (pkg2doc email pkgbuild) ++ "\n")
      case hooks of
        Just hook -> writeFile (install_hook_name (arch_pkgname (pkgBody pkgbuild))) hook
        Nothing -> return ()
