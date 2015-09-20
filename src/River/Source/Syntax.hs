{-# LANGUAGE DeriveDataTypeable #-}

module River.Source.Syntax where

import Data.Data (Data)
import Data.Text (Text)
import Data.Typeable (Typeable)

------------------------------------------------------------------------

data Program a = Program !a ![Statement a]
  deriving (Eq, Ord, Read, Show, Data, Typeable)

data Statement a =
    Declaration !a !Identifier            !(Maybe (Expression a))
  | Assignment  !a !Identifier !(Maybe BinaryOp) !(Expression a)
  | Return      !a                               !(Expression a)
  deriving (Eq, Ord, Read, Show, Data, Typeable)

data Expression a =
    Literal  !a !Integer
  | Variable !a !Identifier
  | Unary    !a !UnaryOp  !(Expression a)
  | Binary   !a !BinaryOp !(Expression a) !(Expression a)
  deriving (Eq, Ord, Read, Show, Data, Typeable)

data Identifier = Identifier !Text
  deriving (Eq, Ord, Read, Show, Data, Typeable)

data UnaryOp = Neg
  deriving (Eq, Ord, Read, Show, Data, Typeable)

data BinaryOp = Add | Sub | Mul | Div | Mod
  deriving (Eq, Ord, Read, Show, Data, Typeable)
