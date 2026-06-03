{-# LANGUAGE NoRebindableSyntax #-}
{-# OPTIONS_GHC -fno-warn-missing-import-lists #-}
{-# OPTIONS_GHC -w #-}
module PackageInfo_network_uri (
    name,
    version,
    synopsis,
    copyright,
    homepage,
  ) where

import Data.Version (Version(..))
import Prelude

name :: String
name = "network_uri"
version :: Version
version = Version [2,6,4,2] []

synopsis :: String
synopsis = "URI manipulation"
copyright :: String
copyright = ""
homepage :: String
homepage = "https://github.com/haskell/network-uri"
