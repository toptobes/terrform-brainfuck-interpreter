module TFGen (genTfFiles) where

import Data.Text qualified as T
import FileActions
import Options

genTfFiles :: Options -> FileActionF ()
genTfFiles opts = do
  when opts.force $ do
    deleteDir opts.outDir
  mkRoot opts opts.outDir

mkRoot :: Options -> FilePath -> FileActionF ()
mkRoot opts dirName = do
  entryFile <- FileDesc "main.tf" <$> useTemplateFile "root/main.tf" []
  
  dirs <- sequence
    [ mkTemplateModule "interpreter" opts.maxInterpSteps
    , mkTemplateModule "bracket_lut" opts.maxLUTGenSteps
    ]

  createDir $ DirDesc dirName [entryFile] dirs

mkTemplateModule :: FilePath -> Int -> FileActionF DirDesc
mkTemplateModule name size = do
  contentStart <- useTemplateFile (name <> "/start.tf") []

  contentIntermediate <- forM [1..size] $ \i -> do
    useTemplateFile (name <> "/step.tf") [("index", show i), ("prev_index", show $ i - 1)]

  contentEnd <- useTemplateFile (name <> "/end.tf") [("prev_index", show size)]

  let content = T.intercalate "\n" $ concat [[contentStart], contentIntermediate, [contentEnd]]
      mainFile = FileDesc "main.tf" content

  pure $ DirDesc ("modules/" <> name) [mainFile] []