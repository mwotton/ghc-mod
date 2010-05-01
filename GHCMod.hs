module Main where

import Browse
import Check
import Control.Applicative
import Control.Exception hiding (try)
import Lang
import List
import Prelude hiding (catch)
import System.Console.GetOpt
import System.Environment (getArgs)
import Types

----------------------------------------------------------------

usage :: String
usage =    "ghc-mod version 0.4.0\n"
        ++ "Usage:\n"
        ++ "\t ghc-mod list\n"
        ++ "\t ghc-mod lang\n"
        ++ "\t ghc-mod browse <module>\n"
        ++ "\t ghc-mod check <HaskellFile>\n"
        ++ "\t ghc-mod help\n"

----------------------------------------------------------------

defaultOptions :: Options
defaultOptions = Options { convert = toPlain }

argspec :: [OptDescr (Options -> Options)]
argspec = [ Option "l" ["tolisp"]
            (NoArg (\opts -> opts { convert = toLisp }))
            "print as a list of Lisp"
          ]

parseArgs :: [OptDescr (Options -> Options)] -> [String] -> (Options, [String])
parseArgs spec argv
    = case getOpt Permute spec argv of
        (o,n,[]  ) -> (foldl (flip id) defaultOptions o, n)
        (_,_,errs) -> error $ concat errs ++ usageInfo usage argspec

----------------------------------------------------------------

main :: IO ()
main = flip catch handler $ do
        (opt,(cmd:rest)) <- parseArgs argspec <$> getArgs
        res <- case cmd of
               "browse" -> concat <$> mapM (browseModule opt) rest
               "list"   -> listModules opt
               "check"  -> checkSyntax opt (head rest)
               "lang"   -> listLanguages opt
               _        -> error usage
        putStr res
  where
    handler :: ErrorCall -> IO ()
    handler _ = putStr usage

----------------------------------------------------------------
toLisp :: [String] -> String
toLisp ms = "(" ++ unwords quoted ++ ")\n"
    where
      quote x = "\"" ++ x ++ "\""
      quoted = map quote ms

toPlain :: [String] -> String
toPlain = unlines
