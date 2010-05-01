import Test.HUnit
import Check
import Maybe
import Data.List

main = runTestTT $ TestList [test_sanity, test_warn]

tester contents label expected = TestCase $ do writeFile "/tmp/T.hs" contents
                                               results <- checkSyntax undefined "/tmp/T.hs"
                                               assertBool (label ++ ": " ++results) (expected `isInfixOf` results)
                           

test_sanity = tester "module T where\nfoo=bar" "should be out of scope" "Not in scope"
test_warn = tester "main = return ()" "should have a typesig" "Definition but no type signature"
