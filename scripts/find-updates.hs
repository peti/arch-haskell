-- Usage: findupdates PKGLIST hackage/

module Main ( main ) where

import System.Directory
import System.Environment
import Data.Version
import Text.ParserCombinators.ReadP
import Distribution.Package
import System.FilePath
import Distribution.Text
import Data.List

readVersion :: String -> Version
readVersion str =
  case [ v | (v,[]) <- readP_to_S parseVersion str ] of
    [ v' ] -> v'
    _      -> error ("invalid version specifier " ++ show str)

readDirectory :: FilePath -> IO [FilePath]
readDirectory dirpath = do
  entries <- getDirectoryContents dirpath
  return [ x | x <- entries, x /= ".", x /= ".." ]

readPkglist :: FilePath -> IO [[String]]
readPkglist path = do
  buf <- readFile path
  return [ words x | x <- lines buf, x /= [], head x /= '#' ]

discoverUpdates :: FilePath -> PackageIdentifier -> IO [Version]
discoverUpdates hackage (PackageIdentifier (PackageName pkgname) version) = do
  versionStrings <- readDirectory (hackage </> pkgname)
  let versions = map readVersion versionStrings
  return [ v | v <- versions, v > version ]

main :: IO ()
main = do
  pkglistFile:hackageDir:[] <- getArgs
  pkglist <- readPkglist pkglistFile
  let pkgs = [ PackageIdentifier (PackageName pkg) (readVersion v) | _:pkg:v:_:[] <- pkglist ]
  newVersions <- mapM (discoverUpdates hackageDir) pkgs
  let updates = [ u | u@(_,vs) <- zip pkgs newVersions, vs /= [] ]
  flip mapM_ updates $ \(pkg,versions) -> do
    putStr (display pkg)
    putStr ": "
    putStrLn $ concat $ intersperse ", " $ map showVersion versions
