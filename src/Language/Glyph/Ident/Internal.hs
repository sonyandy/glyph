{-# LANGUAGE
    DeriveDataTypeable
  , FlexibleInstances
  , MultiParamTypeClasses
  , GeneralizedNewtypeDeriving
  , StandaloneDeriving
  , TemplateHaskell
  , UndecidableInstances #-}
module Language.Glyph.Ident.Internal
       ( Ident (..)
       , freshIdent
       ) where

import Control.Monad

import Data.Data

import Language.Glyph.Unique
import Language.Haskell.TH.Syntax (showName)
import qualified Language.Haskell.TH as TH

import Text.PrettyPrint.Free

newtype Ident
  = Ident { unIdent :: Unique
          } deriving (Eq, Ord, Typeable)

instance Pretty Ident where
  pretty = text . ('$' :) . show . unIdent

instance Show Ident where
  show = show . pretty

instance Data Ident where
  gfoldl _f z = z
  toConstr _ = error "toConstr"
  gunfold _ _ = error "gunfold"
  dataTypeOf _ = mkNoRepType name
    where
      name = $(return . TH.LitE . TH.StringL . showName $ ''Ident)

freshIdent :: UniqueMonad m => m Ident
freshIdent = liftM Ident freshUnique
