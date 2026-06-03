{-# LANGUAGE NoRebindableSyntax #-}
{-# OPTIONS_GHC -fno-warn-missing-import-lists #-}
{-# OPTIONS_GHC -w #-}
module PackageInfo_hsc2hs (
    name,
    version,
    synopsis,
    copyright,
    homepage,
  ) where

import Data.Version (Version(..))
import Prelude

name :: String
name = "hsc2hs"
version :: Version
version = Version [0,68,10] []

synopsis :: String
synopsis = "A preprocessor that helps with writing Haskell bindings to C code"
copyright :: String
copyright = "2000, Marcin Kowalczyk"
homepage :: String
homepage = ""
