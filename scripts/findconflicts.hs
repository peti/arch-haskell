-- |
-- Module    : findconflicts: find inconsistencies between versions reqs of a package list
-- Copyright : (c) Rémy Oudompheng 2010
-- License   : BSD3
--
-- Maintainer: Arch Haskell Team <arch-haskell@haskell.org>
-- Stability : provisional
-- Portability:
--

-- 
-- Usage: findconflicts PKGLIST 00-index.tar

import Distribution.ArchLinux.HackageTranslation
import Distribution.ArchLinux.SystemProvides

import Distribution.Package
import Distribution.PackageDescription
import Distribution.Text
import Text.PrettyPrint

import qualified Data.ByteString.Lazy as Bytes
import System.Environment
import System.Exit

displayConflict :: PackageDescription -> Dependency -> IO ()
displayConflict pkg dep = do
  let name = disp $ pkgName $ packageId pkg
  putStrLn $ render (name <+> text "needs" <+> disp dep)

main :: IO ()
main = do
  argv <- getArgs
  _ <- case argv of
    _:_:_ -> return ()
    _ -> exitWith (ExitFailure 1)
  pkglist <- readFile (argv !! 0)
  tarball <- Bytes.readFile (argv !! 1)
  sysProvides <- getDefaultSystemProvides
  let cabals = getSpecifiedCabalsFromTarball tarball (lines pkglist)
      conflicts = getVersionConflicts cabals sysProvides
  _ <- mapM (uncurry displayConflict) conflicts
  return ()
