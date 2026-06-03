{-# LANGUAGE NoRebindableSyntax #-}
{-# OPTIONS_GHC -fno-warn-missing-import-lists #-}
{-# OPTIONS_GHC -w #-}
module PackageInfo_easy_file (
    name,
    version,
    synopsis,
    copyright,
    homepage,
  ) where

import Data.Version (Version(..))
import Prelude

name :: String
name = "easy_file"
version :: Version
version = Version [0,2,5] []

synopsis :: String
synopsis = "Cross-platform File handling"
copyright :: String
copyright = ""
homepage :: String
homepage = "http://github.com/kazu-yamamoto/easy-file"
