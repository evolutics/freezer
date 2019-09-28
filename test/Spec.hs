import qualified Buffet.Toolbox.JsonTools as JsonTools
import qualified Buffet.Toolbox.TestTools as TestTools
import qualified Buffet.Toolbox.TextTools as TextTools
import qualified Data.Text as T
import Prelude
  ( FilePath
  , IO
  , String
  , ($)
  , (.)
  , (<$>)
  , (>>=)
  , fmap
  , pure
  , sequenceA
  )
import qualified System.Directory as Directory
import qualified System.FilePath as FilePath
import qualified System.Process.Typed as Process
import qualified Test.Tasty as Tasty

main :: IO ()
main = tests >>= Tasty.defaultMain

tests :: IO Tasty.TestTree
tests =
  Tasty.testGroup "Tests" <$>
  sequenceA
    [ Tasty.testGroup "Build" <$> buildTests "test/data/build"
    , Tasty.testGroup "Document" <$> documentTests "test/data/document"
    , Tasty.testGroup "Parse" <$> parseTests "test/data/parse"
    , Tasty.testGroup "Test" <$> testTests "test/data/test"
    , pure mainDockerfileTest
    ]
  where
    mainDockerfileTest =
      TestTools.assertFileEqualsText "Main" "Dockerfile" $ build ["dockerfiles"]

buildTests :: FilePath -> IO [Tasty.TestTree]
buildTests = TestTools.folderBasedTests assert
  where
    assert name path =
      pure . TestTools.assertFileEqualsText name (expected path) $ actual path
    expected path = FilePath.combine path "expected.Dockerfile"
    actual path = build [path]

build :: [String] -> IO T.Text
build =
  fmap TextTools.decodeUtf8 .
  Process.readProcessStdout_ . Process.proc executable . ("build" :)

executable :: FilePath
executable = "buffet-exe"

documentTests :: FilePath -> IO [Tasty.TestTree]
documentTests = TestTools.folderBasedTests assert
  where
    assert name path = do
      hasCustomTemplate <- Directory.doesFileExist customTemplate
      let (expected, actual) =
            if hasCustomTemplate
              then ( FilePath.combine path "expected.md"
                   , document ["--template", customTemplate, path])
              else (FilePath.combine path "expected.json", document [path])
      pure $ TestTools.assertFileEqualsText name expected actual
      where
        customTemplate = FilePath.combine path "template.md.mustache"

document :: [String] -> IO T.Text
document =
  fmap TextTools.decodeUtf8 .
  Process.readProcessStdout_ . Process.proc executable . ("document" :)

parseTests :: FilePath -> IO [Tasty.TestTree]
parseTests folder = do
  expectedBase <-
    JsonTools.decodeFile $ FilePath.combine folder "expected_base.json"
  let assert name path =
        pure .
        TestTools.assertJsonComposedFileEqualsText
          name
          expectedBase
          (expectedOverride path) $
        actual path
  TestTools.folderBasedTests assert folder
  where
    expectedOverride path = FilePath.combine path "expected.json"
    actual path = parse [path]

parse :: [String] -> IO T.Text
parse =
  fmap TextTools.decodeUtf8 .
  Process.readProcessStdout_ . Process.proc executable . ("parse" :)

testTests :: FilePath -> IO [Tasty.TestTree]
testTests = TestTools.folderBasedTests assert
  where
    assert name path = do
      hasCustomArguments <- Directory.doesFileExist customArguments
      let actual =
            if hasCustomArguments
              then test ["--arguments", customArguments, path]
              else test [path]
      pure $ TestTools.assertFileEqualsText name expected actual
      where
        customArguments = FilePath.combine path "arguments.yaml"
        expected = FilePath.combine path "expected.json"

test :: [String] -> IO T.Text
test =
  fmap TextTools.decodeUtf8 .
  Process.readProcessStdout_ . Process.proc executable . ("test" :)
