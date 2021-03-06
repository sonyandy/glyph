{-# LANGUAGE
    DeriveDataTypeable
  , GeneralizedNewtypeDeriving
  , MultiParamTypeClasses #-}
module Language.Glyph.Logger
       ( LoggerT
       , LoggerException (..)
       , runLoggerT
       ) where

import Control.Applicative
import Control.Exception
import qualified Control.Monad.Trans as Trans
import Control.Monad.State hiding (liftIO, put)
import Control.Monad.Writer.Class
import qualified Control.Monad.State as State

import Data.Typeable

import Language.Glyph.Message

import System.IO

newtype LoggerT m a
  = LoggerT ( StateT S m a
            ) deriving ( Functor
                       , Applicative
                       , Monad
                       , MonadIO
                       , MonadFix
                       )

data LoggerException
  = PreviousErrors deriving Typeable

instance Show LoggerException where
  show _ = "failed due to previous errors"

instance Exception LoggerException

type S = Bool

instance MonadIO m => MonadWriter Message (LoggerT m) where
  tell x =
    case x of
      Warning w ->
        liftIO $ hPutStrLn stderr ("warning: " ++ show w)
      Error e -> do
        liftIO $ hPutStrLn stderr ("error: " ++ show e)
        put True

runLoggerT :: MonadIO m => LoggerT m a -> m a
runLoggerT (LoggerT m) = do
  (a, s) <- runStateT m False
  when s $ Trans.liftIO $ throwIO PreviousErrors
  return a

put :: Monad m => S -> LoggerT m ()
put = LoggerT . State.put

liftIO :: MonadIO m => IO a -> LoggerT m a
liftIO = LoggerT . Trans.liftIO
