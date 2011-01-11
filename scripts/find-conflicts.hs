-- Usage: find-conflicts CabalFile...

module Main ( main ) where

import System.Environment ( getArgs )
import Distribution.Package ( packageId )
import Distribution.ArchLinux.HackageTranslation ( getVersionConflicts )
import Distribution.ArchLinux.SystemProvides ( parseSystemProvides )
import Distribution.PackageDescription.Parse ( readPackageDescription )
import Distribution.Verbosity ( silent )
import Distribution.Text ( disp )
import Text.PrettyPrint

main :: IO ()
main = do
  cabalFiles <- getArgs
  pkgs <- mapM (readPackageDescription silent) cabalFiles
  fc <- readFile "data/ghc-provides.txt"
  fp <- readFile "data/platform-provides.txt"
  ft <- readFile "data/library-providers.txt"
  let sysProvides = parseSystemProvides fc fp ft
  case getVersionConflicts pkgs sysProvides of
    []        -> return ()
    conflicts -> do
      let name pkg               = disp (packageId pkg)
          showConflict (pkg,dep) = render (name pkg <+> text "needs" <+> disp dep)
      mapM_ (putStrLn . showConflict) conflicts
      fail "conflicts detected"
