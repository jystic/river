{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
module River.Core.Analysis.Interference (
    InterferenceGraph
  , mapOfInterference
  , neighbors
  , fromNeighboring
  , ppInterferenceGraph

  , InterferenceError(..)
  , interferenceOfProgram
  , interferenceOfTerm
  ) where

import           Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map
import           Data.Monoid ((<>))
import           Data.Set (Set)
import qualified Data.Set as Set

import           River.Bifunctor
import           River.Core.Analysis.Live
import           River.Core.Annotation
import           River.Core.Syntax

import           Text.PrettyPrint.Boxes ((//), (<+>))
import qualified Text.PrettyPrint.Boxes as Box


newtype InterferenceGraph n =
  InterferenceGraph (Map n (Set n))
  deriving (Eq, Ord, Show)

instance Ord n => Monoid (InterferenceGraph n) where
  mempty =
    InterferenceGraph Map.empty

  mappend (InterferenceGraph xs) (InterferenceGraph ys) =
    InterferenceGraph $
      Map.unionWith Set.union xs ys

mapOfInterference :: InterferenceGraph n -> Map n (Set n)
mapOfInterference (InterferenceGraph xs) =
  xs

neighbors :: Ord n => n -> InterferenceGraph n -> Maybe (Set n)
neighbors n =
  Map.lookup n . mapOfInterference

fromNeighboring :: forall n. Ord n => Set n -> InterferenceGraph n
fromNeighboring =
  let
    go :: [n] -> [n] -> [(n, Set n)]
    go xs = \case
     [] ->
       []
     y : ys ->
       (y, Set.fromList (xs ++ ys)) : go (y : xs) ys
  in
    InterferenceGraph . Map.fromList . go [] . Set.toList

------------------------------------------------------------------------

data InterferenceError n =
    InterferenceLiveError !(LiveError n)
    deriving (Eq, Ord, Show)

-- | Find the interference graph of a program.
interferenceOfProgram ::
  Ord n =>
  Program k p n a ->
  Either (InterferenceError n) (InterferenceGraph n)
interferenceOfProgram = \case
  Program _ tm ->
    interferenceOfTerm tm

interferenceOfTerm :: Ord n => Term k p n a -> Either (InterferenceError n) (InterferenceGraph n)
interferenceOfTerm =
  fmap interferenceOfAnnotTerm . first InterferenceLiveError . liveOfTerm

interferenceOfAnnotTerm :: Ord n => Term k p n (Live n a) -> InterferenceGraph n
interferenceOfAnnotTerm = \case
 Return a _ ->
   fromNeighboring (liveVars a)
 If a _ _ t e ->
   fromNeighboring (liveVars a) <>
   interferenceOfAnnotTerm t <>
   interferenceOfAnnotTerm e
 Let a ns _ tm ->
   -- when there are no dead bindings then:
   --
   --   liveOfAnnotTerm tm = liveOfAnnotTerm tm <> Set.fromList ns
   --
   fromNeighboring (liveVars a) <>
   fromNeighboring (liveOfAnnotTerm tm <> Set.fromList ns) <>
   interferenceOfAnnotTerm tm
 LetRec a bs tm ->
   fromNeighboring (liveVars a) <>
   interferenceOfAnnotBindings bs <>
   interferenceOfAnnotTerm tm

interferenceOfAnnotBindings :: Ord n => Bindings k p n (Live n a) -> InterferenceGraph n
interferenceOfAnnotBindings = \case
  Bindings a bs ->
    fromNeighboring (liveVars a) <>
    -- Function names can't interfere as they are labels rather than registers.
    -- Maybe they should have a different name type?
    mconcat (fmap (interferenceOfAnnotBinding . snd) bs)

interferenceOfAnnotBinding :: Ord n => Binding k p n (Live n a) -> InterferenceGraph n
interferenceOfAnnotBinding = \case
  Lambda a ns tm ->
    fromNeighboring (liveVars a) <>
    fromNeighboring (liveOfAnnotTerm tm <> Set.fromList ns) <>
    interferenceOfAnnotTerm tm

liveOfAnnotTerm :: Term k p n (Live n a) -> Set n
liveOfAnnotTerm =
  liveVars . annotOfTerm

------------------------------------------------------------------------

ppInterferenceGraph :: (n -> String) -> InterferenceGraph n -> String
ppInterferenceGraph ppName g =
  let
    (names, neighbors') =
      unzip . Map.toList $ mapOfInterference g

    nameBox =
      Box.text . ppName

    nameColumn =
      Box.vcat Box.left $
      fmap nameBox names

    arrowColumn =
      Box.vcat Box.left (Box.text "->" <$ names)

    neighborsColumn =
      Box.vcat Box.left $
      fmap (neighborsRow . Set.toList) neighbors'

    neighborsRow = \case
      [] ->
        Box.text "(none)"
      xs ->
        Box.hsep 1 Box.left $
        fmap nameBox xs

    column label rows =
      let
        header =
          Box.alignHoriz Box.center1 (length label `max` Box.cols rows) (Box.text label)

        divider =
          Box.text (replicate (length label `max` Box.cols rows) '=')
      in
        header // divider // rows
  in
    reverse .
    dropWhile (== '\n') .
    reverse .
    Box.render $
      (column "Var" nameColumn) <+>
      (Box.emptyBox 2 1 // arrowColumn) <+>
      (column "Neighbors" neighborsColumn)
