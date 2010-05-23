module Main where

import Browse
import Check
import Control.Applicative
import Control.Exception hiding (try)
import Lang
import Lint
import List
import Prelude hiding (catch)
import System.Console.GetOpt
import System.Directory
import System.Environment (getArgs)
import Types

----------------------------------------------------------------

usage :: String
usage =    "ghc-mod version 0.4.1\n"
        ++ "Usage:\n"
        ++ "\t ghc-mod list\n"
        ++ "\t ghc-mod lang\n"
        ++ "\t ghc-mod browse <module> [<module> ...]\n"
        ++ "\t ghc-mod check <HaskellFile>\n"
        ++ "\t ghc-mod lint <HaskellFile>\n"
        ++ "\t ghc-mod boot\n"
        ++ "\t ghc-mod help\n"

----------------------------------------------------------------

defaultOptions :: Options
defaultOptions = Options {
    convert = toPlain
  , hlint = "hlint"
  }

argspec :: [OptDescr (Options -> Options)]
argspec = [ Option "l" ["tolisp"]
            (NoArg (\opts -> opts { convert = toLisp }))
            "print as a list of Lisp"
          , Option "f" ["hlint"]
            (ReqArg (\str opts -> opts { hlint = str }) "hlint")
            "path to hlint"
          ]

parseArgs :: [OptDescr (Options -> Options)] -> [String] -> (Options, [String])
parseArgs spec argv
    = case getOpt Permute spec argv of
        (o,n,[]  ) -> (foldl (flip id) defaultOptions o, n)
        (_,_,errs) -> error $ concat errs ++ usageInfo usage argspec

----------------------------------------------------------------

main :: IO ()
main = flip catch handler $ do
    args <- getArgs
    let (opt,cmdArg) = parseArgs argspec args
    res <- case head cmdArg of
      "browse" -> concat <$> mapM (browseModule opt) (tail cmdArg)
      "list"   -> listModules opt
      "check"  -> withFile (checkSyntax opt) (cmdArg !! 1)
      "lint"   -> withFile (lintSyntax opt) (cmdArg !! 1)
      "lang"   -> listLanguages opt
      "boot"   -> do
         mods  <- listModules opt
         langs <- listLanguages opt
         pre   <- browseModule opt "Prelude"
         return $ mods ++ langs ++ pre
      _        -> error usage
    putStr res

  where
    handler :: ErrorCall -> IO ()
    handler _ = putStr usage
    withFile cmd file = do
        exist <- doesFileExist file
        if exist
            then cmd file
            else return ""

----------------------------------------------------------------
toLisp :: [String] -> String
toLisp ms = "(" ++ unwords quoted ++ ")\n"
    where
      quote x = "\"" ++ x ++ "\""
      quoted = map quote ms

toPlain :: [String] -> String
toPlain = unlines
