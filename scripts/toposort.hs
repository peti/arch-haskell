--
-- | This test reads the given directory and dumps a topologically sorted package list.
--

import Distribution.ArchLinux.SrcRepo ( getRepoFromDir, dumpContentsTopo )
import System.Environment ( getArgs )

main = do
  habs:[] <- getArgs
  repo <- getRepoFromDir habs
  case repo of
    Nothing -> fail ("cannot load habs tree at " ++ show habs)
    Just r -> mapM_ putStrLn (dumpContentsTopo r)
