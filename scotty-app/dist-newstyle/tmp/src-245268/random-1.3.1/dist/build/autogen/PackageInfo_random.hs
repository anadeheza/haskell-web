{-# LANGUAGE NoRebindableSyntax #-}
{-# OPTIONS_GHC -fno-warn-missing-import-lists #-}
{-# OPTIONS_GHC -w #-}
module PackageInfo_random (
    name,
    version,
    synopsis,
    copyright,
    homepage,
  ) where

import Data.Version (Version(..))
import Prelude

name :: String
name = "random"
version :: Version
version = Version [1,3,1] []

synopsis :: String
synopsis = "Pseudo-random number generation"
copyright :: String
copyright = ""
homepage :: String
homepage = ""
