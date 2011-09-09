{-# LANGUAGE MultiParamTypeClasses #-}

module System.TPFS.Device (Device(..), Interleave(..)) where

import           Control.Applicative
import           Data.ByteString.Lazy (ByteString,hGet,hPut)
import qualified Data.ByteString.Lazy as B
import           System.IO
import           System.IO.Unsafe (unsafeInterleaveIO)
import           System.TPFS.Address

class (Functor m, Applicative m, Monad m, Interleave m) => Device m h where
  dGet :: Integral i
       => h
       -> Address
       -> i
       -> m ByteString

  dPut :: h
       -> Address
       -> ByteString
       -> m ()

-- | Only necessary for IO -- the default implementation should be
-- sufficient for most monads.
class Monad m => Interleave m where
  interleave :: m a -> m a
  interleave  = id

instance Device IO Handle where
  dGet h off len =
    do hSeek h AbsoluteSeek (toInteger off)
       r <- hGetI h len
       if B.length r < fromIntegral len
          then return (r `B.append` B.replicate (fromIntegral len - B.length r) 0)
          else return  r
  dPut h off s =
    do hSeek h AbsoluteSeek (toInteger off)
       hPut  h s

hGetI          :: Integral l => Handle -> l -> IO ByteString
hGetI h l
    | l > mbi   = B.append <$> hGet h maxBound <*> hGetI h (l - mbi)
    | otherwise = hGet h (fromEnum l)
  where   mbi   = fromIntegral (maxBound :: Int)

instance Interleave IO where
  interleave = unsafeInterleaveIO