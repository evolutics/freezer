module Buffet.Assemble.GlobalBuildStage
  ( get
  ) where

import qualified Buffet.Assemble.ConditionInstructionsInContext as ConditionInstructionsInContext
import qualified Buffet.Assemble.ScheduleParallelInstructions as ScheduleParallelInstructions
import qualified Buffet.Ir.Ir as Ir
import qualified Data.Map.Strict as Map
import Prelude (($), (.), fmap, uncurry)

get :: Ir.Buffet -> [Ir.DockerfilePart]
get = ScheduleParallelInstructions.get . dishesInstructions

dishesInstructions :: Ir.Buffet -> [Ir.DockerfilePart]
dishesInstructions buffet =
  fmap (uncurry $ dishInstructions buffet) . Map.toAscList $
  Ir.optionToDish buffet

dishInstructions :: Ir.Buffet -> Ir.Option -> Ir.Dish -> Ir.DockerfilePart
dishInstructions buffet option =
  ConditionInstructionsInContext.get buffet option . Ir.globalBuildStage
