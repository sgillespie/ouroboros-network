{-# LANGUAGE FlexibleInstances          #-}
{-# LANGUAGE GADTs                      #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE RankNTypes                 #-}
{-# LANGUAGE StandaloneDeriving         #-}

module Ouroboros.Network.Protocol.LocalStateQuery.Codecs where

import Codec.CBOR.Decoding qualified as CBOR
import Codec.CBOR.Encoding qualified as CBOR
import Codec.CBOR.Read qualified as CBOR
import Codec.Serialise (Serialise)
import Codec.Serialise.Class qualified as Serialise
import Data.ByteString.Lazy qualified as BL
import Network.TypedProtocol.Codec
import Ouroboros.Network.Protocol.BlockFetch.Codecs (Block, BlockPoint)
import Ouroboros.Network.Protocol.LocalStateQuery.Codec
import Ouroboros.Network.Protocol.LocalStateQuery.Type
import Test.Data.CDDL (Any)
import Test.QuickCheck (Arbitrary (..))

newtype Result = Result Any
  deriving (Eq, Show, Arbitrary, Serialise)

-- TODO: add payload to the query
data Query result where
    Query :: Any -> Query Result

encodeQuery :: Query result -> CBOR.Encoding
encodeQuery (Query a) = Serialise.encode a

decodeQuery :: forall s. CBOR.Decoder s (Some Query)
decodeQuery = Some . Query <$> Serialise.decode

instance ShowQuery Query where
    showResult (Query query) result = show (query, result)
deriving instance Show (Query result)

instance Arbitrary (Query Result) where
    arbitrary = Query <$> arbitrary

localStateQueryCodec :: Codec (LocalStateQuery Block BlockPoint Query)
                              CBOR.DeserialiseFailure IO BL.ByteString
localStateQueryCodec =
    codecLocalStateQuery
      maxBound
      Serialise.encode Serialise.decode
      encodeQuery decodeQuery
      (\Query{} -> Serialise.encode) (\Query{} -> Serialise.decode)

