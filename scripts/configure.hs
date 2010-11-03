import System.IO
import System.Environment
import Control.Monad.RWS
import Distribution.Package
import Distribution.Text
import Data.Version
import Distribution.Compat.ReadP

data Config = Config
  { pkglistFile :: FilePath
  , hackageDir :: FilePath
  , habsDir :: FilePath
  }
  deriving (Show)

defaultConfig = Config
  { pkglistFile = "PKGLIST"
  , hackageDir = "hackage"
  , habsDir = "habs"
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
  deriving (Show)

readPkglist :: FilePath -> IO [PkgSpec]
readPkglist = fmap parsePkglist . readFile

parsePkglist :: String -> [PkgSpec]
parsePkglist buf = map parsePkglistLine wordList
  where
    wordList' = [ words l | l <- lines buf ]
    wordList  = [ ws | ws <- wordList', ws /= [], head ws /= "#" ]

parsePkglistLine :: [String] -> PkgSpec
parsePkglistLine (an:cn:v:r:[]) = PkgSpec (PackageName an) (PackageName cn) (parseDet v) (read r)

parseDet :: (Text a) => String -> a
parseDet str = case [ v | (v,[]) <- readP_to_S parse str ] of
                 [] -> error ("cannot parse input " ++ show str)
                 [a] -> a

main :: IO ()
main = do
  pkglist <- readPkglist "PKGLIST"
  mapM_ print pkglist
