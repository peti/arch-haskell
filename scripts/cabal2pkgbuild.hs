module Main ( main ) where

-- package: Cabal
import Distribution.PackageDescription.Parse ( readPackageDescription )
import Distribution.Verbosity ( normal )

-- package: archlinux
import Distribution.ArchLinux.PkgBuild ( pkg2doc, arch_pkgname, pkgBody )
import Distribution.ArchLinux.CabalTranslation ( preprocessCabal, cabal2pkg, install_hook_name )
import Distribution.ArchLinux.SystemProvides ( getDefaultSystemProvides )

-- package: base
import Text.PrettyPrint ( render )
import System.Environment ( getArgs )
import System.FilePath ( (</>) )

main :: IO ()
main = do
  cabalFile:outputDir:[] <- getArgs
  let email = "Arch Haskell Team <arch-haskell@haskell.org>"
  cabalSrc  <- readPackageDescription normal cabalFile
  systemPkgs <- getDefaultSystemProvides
  case preprocessCabal cabalSrc systemPkgs of
    Nothing -> fail ("cannot parse and/or resolve " ++ show cabalFile)
    Just cabalPkg -> do
      let (pkgbuild, Just hooks) = cabal2pkg cabalPkg systemPkgs
      writeFile (outputDir </> "PKGBUILD") (render (pkg2doc email pkgbuild) ++ "\n")
      writeFile (outputDir </> (install_hook_name (arch_pkgname (pkgBody pkgbuild)))) hooks
