module Main ( main ) where

import System.Environment ( getArgs )
import Distribution.PackageDescription.Parse ( readPackageDescription )
import Distribution.Verbosity ( silent )
import Distribution.Text ( display )
import Distribution.ArchLinux.CabalTranslation ( preprocessCabal, cabal2pkg', install_hook_name )
import Distribution.ArchLinux.SystemProvides ( parseSystemProvides )
import Distribution.ArchLinux.PkgBuild ( arch_pkgname, pkgBody )

main :: IO ()
main = do
  cabalFile:archname:release:[] <- getArgs
  let
  cabalSrc <- readPackageDescription silent cabalFile
  fc <- readFile "../../../data/ghc-provides.txt"
  fp <- readFile "../../../data/platform-provides.txt"
  ft <- readFile "../../../data/library-providers.txt"
  let systemPkgs = parseSystemProvides fc fp ft
  case preprocessCabal cabalSrc systemPkgs of
    Nothing -> fail ("cannot parse and/or resolve " ++ show cabalFile)
    Just cabalPkg -> do
      let (pkgbuild, hooks) = cabal2pkg' cabalPkg archname (read release) systemPkgs
          header            = "# Maintainer: Arch Haskell Team <arch-haskell@haskell.org>\n"
          body              = display pkgbuild ++ "\n"
      writeFile "PKGBUILD" (header ++ body)
      case hooks of
        Just hook -> writeFile (install_hook_name (arch_pkgname (pkgBody pkgbuild))) hook
        Nothing -> return ()
