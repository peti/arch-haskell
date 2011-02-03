import Data.Functor
import System.IO
import System.FilePath
import System.Environment
import System.Directory
import Control.Monad.RWS
import Distribution.Package
import Distribution.Text
import Data.Version
import Distribution.Compat.ReadP
import Text.PrettyPrint
import qualified Data.Set as Set
import qualified Data.Map as Map
import Distribution.PackageDescription.Configuration
import Distribution.PackageDescription.Parse
import Distribution.PackageDescription
import Distribution.Verbosity ( normal )

data Config = Config
  { pkgset :: PkgSet
  , syspkgset :: PkgSet
  , habsdir :: FilePath
  , hackagedir :: FilePath
  }
  deriving (Show)

defaultConfig = Config
  { pkgset = PkgSet Set.empty
  , syspkgset = PkgSet Set.empty
  , habsdir = "habs"
  , hackagedir = "hackage"
  }

type Gen a = RWST Config String () IO a

runGenerator :: Config -> Gen a -> IO (a, String)
runGenerator cfg f = evalRWST f cfg ()

data PkgSpec = PkgSpec
  { archName :: PackageName
  , cabalName :: PackageName
  , pkgVersion :: Version
  , pkgRelease :: Int
  }
  deriving (Show, Eq, Ord)

instance Text PkgSpec where
  disp (PkgSpec ac cn v r) = hsep [disp ac, disp cn, disp v, int r]
  parse = do archname <- parse
             () <- skipSpaces
             cabalname <- parse
             () <- skipSpaces
             pkgversion <- parse
             () <- skipSpaces
             pkgrel <- readS_to_P (readsPrec 0)
             return (PkgSpec archname cabalname pkgversion pkgrel)

newtype PkgSet = PkgSet (Set.Set PkgSpec)
  deriving (Show)

instance Text PkgSet where
  disp (PkgSet ps) = vcat [ disp p | p <- Set.toAscList ps ]
  parse = PkgSet . Set.fromList <$> many dataLine
    where
      dataLine = do
        _ <- many comment
        pkgspec <- parse
        _ <- Distribution.Compat.ReadP.char '\n'
        return pkgspec
      comment = do
        _ <- Distribution.Compat.ReadP.char '#'
        _ <- munch (/='\n')
        _ <- Distribution.Compat.ReadP.char '\n'
        return ()

readPkglist :: FilePath -> IO [PkgSpec]
readPkglist = fmap parsePkglist . readFile

parsePkglist :: String -> [PkgSpec]
parsePkglist buf = map (readText "pkglist entry") dataLines
  where
    isComment []      = True
    isComment ('#':_) = True
    isComment _       = False
    dataLines         = [ l | l <- lines buf, not (isComment l) ]

    wordList' = [ words l | l <- lines buf ]
    wordList  = [ ws | ws <- wordList', ws /= [], head ws /= "#" ]

readText :: (Text a) => String -> String -> a
readText errctx str = maybe err id (simpleParse str)
  where
    err = error ("invalid " ++ errctx ++ ": " ++ show str)

main :: IO ()
main = do
  argv <- getArgs
  when (length argv /= 2) (fail "Usage: PKGLIST hackage")
  let pkglistFile:hackageDir:[] = argv
  pkgset@(PkgSet _) <- readText "package list" <$> readFile pkglistFile
  hackage <- discoverHackage hackageDir
  putStrLn (display pkgset)

discoverHackage :: FilePath -> IO [(PackageName,[Version])]
discoverHackage hackageDir = do
  let metaNames = [".",".."]
      fileNames = ["preferred-versions",".extraction-datestamp"]
      badNames  = metaNames ++ fileNames
  packageNames <- filter (`notElem` badNames) <$> getDirectoryContents hackageDir
  flip mapM packageNames $ \cabalName -> do
    versions <- filter (`notElem` metaNames) <$> getDirectoryContents (hackageDir </> cabalName)
    return (readText "cabal package name" cabalName, map (readText "version specifier") versions)
