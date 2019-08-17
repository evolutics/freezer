module Dockerfile.Intermediate
  ( Box(..)
  , DockerfilePart
  , Utility(..)
  , mapOrderedEntries
  ) where

import qualified Control.Applicative as Applicative
import qualified Data.Map.Strict as Map
import qualified Data.Text as T
import qualified Language.Docker as Docker
import Prelude (Eq, Ord, Show, uncurry)

newtype Box =
  Box
    { optionToUtility :: Map.Map T.Text Utility
    }
  deriving (Eq, Ord, Show)

data Utility =
  Utility
    { beforeFirstBuildStage :: DockerfilePart
    , localBuildStages :: [DockerfilePart]
    , globalBuildStage :: DockerfilePart
    }
  deriving (Eq, Ord, Show)

type DockerfilePart = [Docker.Instruction T.Text]

mapOrderedEntries :: (T.Text -> Utility -> a) -> Box -> [a]
mapOrderedEntries function box =
  uncurry function Applicative.<$> Map.toAscList map
  where
    map = optionToUtility box