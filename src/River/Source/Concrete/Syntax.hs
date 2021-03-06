{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE DeriveFoldable #-}
{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveTraversable #-}
module River.Source.Concrete.Syntax (
    Program(..)
  , Block(..)
  , Statement(..)
  , Simple(..)
  , Control(..)
  , LValue(..)
  , Expression(..)
  , PostOp(..)
  , AssignOp(..)
  , BinaryOp(..)

  -- * Re-exports from River.Source.Syntax.Abstract
  , Literal(..)
  , Identifier(..)
  , Type(..)
  , UnaryOp(..)
  ) where

import           Control.DeepSeq (NFData)

import           Data.Data (Data)
import           Data.Typeable (Typeable)

import           GHC.Generics (Generic)

import           River.Source.Syntax (Literal(..), Identifier(..), Type(..))
import           River.Source.Syntax (UnaryOp(..))


data Program a =
    Program !a !(Block a)
    deriving (Eq, Ord, Read, Show, Functor, Foldable, Traversable, Data, Typeable, Generic, NFData)

data Block a =
    Block !a ![Statement a]
    deriving (Eq, Ord, Read, Show, Functor, Foldable, Traversable, Data, Typeable, Generic, NFData)

data Statement a =
    SSimple !a !(Simple a)
  | SControl !a !(Control a)
  | SBlock !a !(Block a)
    deriving (Eq, Ord, Read, Show, Functor, Foldable, Traversable, Data, Typeable, Generic, NFData)

data Simple a =
    Assign !a !(LValue a) !AssignOp !(Expression a)
  | Post !a !(LValue a) !PostOp
  | Declare  !a !Type !Identifier !(Maybe (Expression a))
    deriving (Eq, Ord, Read, Show, Functor, Foldable, Traversable, Data, Typeable, Generic, NFData)

data Control a =
    If !a !(Expression a) !(Statement a) !(Maybe (Statement a))
  | While !a !(Expression a) !(Statement a)
  | For !a !(Maybe (Simple a)) !(Expression a) !(Maybe (Simple a)) !(Statement a)
  | Return !a !(Expression a)
    deriving (Eq, Ord, Read, Show, Functor, Foldable, Traversable, Data, Typeable, Generic, NFData)

data LValue a =
    LIdentifier !a !Identifier
    deriving (Eq, Ord, Read, Show, Functor, Foldable, Traversable, Data, Typeable, Generic, NFData)

data Expression a =
    Literal !a !Literal
  | Variable !a !Identifier
  | Unary !a !UnaryOp !(Expression a)
  | Binary !a !BinaryOp !(Expression a) !(Expression a)
  | Conditional !a !(Expression a) !(Expression a) !(Expression a)
    deriving (Eq, Ord, Read, Show, Functor, Foldable, Traversable, Data, Typeable, Generic, NFData)

data PostOp =
    Inc
  | Dec
    deriving (Eq, Ord, Read, Show, Data, Typeable, Generic, NFData)

data AssignOp =
    AEq
  | AAdd
  | ASub
  | AMul
  | ADiv
  | AMod
  | AAnd
  | AXor
  | AOr
  | AShl
  | AShr
    deriving (Eq, Ord, Read, Show, Data, Typeable, Generic, NFData)

data BinaryOp =
    Mul
  | Div
  | Mod
  | Add
  | Sub
  | Shl
  | Shr
  | Lt
  | Le
  | Gt
  | Ge
  | Eq
  | Ne
  | BAnd
  | BXor
  | BOr
  | LAnd
  | LOr
    deriving (Eq, Ord, Read, Show, Data, Typeable, Generic, NFData)
