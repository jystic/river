{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE DeriveGeneric #-}
module River.Core.Primitive (
    Prim(..)
  ) where

import           Control.DeepSeq (NFData)

import           Data.Data (Data)
import           Data.Typeable (Typeable)

import           GHC.Generics (Generic)


data Prim =
    Neg
  | Add
  | Sub
  | Mul
  | Div
  | Mod
    deriving (Eq, Ord, Read, Show, Data, Typeable, Generic, NFData)

