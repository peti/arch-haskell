-- |
-- Module    : findupdates: find new packages from Hackage
-- Copyright : (c) Rémy Oudompheng 2010
-- License   : BSD3
--
-- Maintainer: Arch Haskell Team <arch-haskell@haskell.org>
-- Stability : provisional
-- Portability:
--

-- 
-- Usage: findupdates PKGLIST 00-index.tar

import Distribution.ArchLinux.HackageTranslation
import Distribution.Version

import Distribution.Package
import Distribution.PackageDescription
import Distribution.Text
import Text.PrettyPrint

import qualified Data.Map as M
import qualified Data.ByteString.Lazy as Bytes
import System.Environment
import System.Exit
import Data.Maybe
import Debug.Trace

needsUpdate :: GenericPackageDescription -> M.Map PackageName Version -> Maybe PackageIdentifier
needsUpdate pkg m = case M.lookup (pkgName i) m of
      Nothing -> trace (render (text "Package" <+> disp (pkgName i) <+> text "does not exist ???")) Nothing
      Just v -> if v > pkgVersion i
                then Just i { pkgVersion = v }
                else Nothing
  where i = packageId pkg

main :: IO ()
main = do
  argv <- getArgs
  _ <- case argv of
    _:_:_ -> return ()
    _ -> exitWith (ExitFailure 1)
  pkglist <- readFile (argv !! 0)
  tarball <- Bytes.readFile (argv !! 1)
  let allcabals = getCabalsFromTarball tarball
      cabals = getSpecifiedCabalsFromTarball tarball (lines pkglist)
      allversions = getLatestVersions allcabals
      updates = mapMaybe (\p -> needsUpdate p allversions) cabals
  _ <- mapM (\i -> putStrLn $ render (disp i <+> text "is available")) updates
  return ()
