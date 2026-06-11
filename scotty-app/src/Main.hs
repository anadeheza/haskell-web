{-# LANGUAGE OverloadedStrings #-}

module Main where

import Web.Scotty
import Data.Text.Lazy          (Text)
import qualified Data.Text.Lazy as TL
import qualified Data.Text.Lazy.IO as TLIO
import Data.List               (sortBy, isPrefixOf, isSuffixOf)
import Data.Ord                (comparing, Down(..))
import System.Directory        (listDirectory)
import System.FilePath         ((</>), dropExtension, takeFileName)
import Prelude hiding          (readFile)
import Network.Wai.Middleware.Static (staticPolicy, addBase)
import System.Environment (lookupEnv)
import Data.Maybe (fromMaybe)

data Post = Post
  { postSlug    :: Text   
  , postTitle   :: Text
  , postDate    :: Text
  , postExcerpt :: Text
  , postBody    :: Text  
  } deriving (Show)

renderMarkdown :: [Text] -> Text
renderMarkdown [] = ""
renderMarkdown (l:ls)
  | TL.isPrefixOf "## " l  = tag "h2" (TL.drop 3 l) <> renderMarkdown ls
  | TL.isPrefixOf "# "  l  = tag "h1" (TL.drop 2 l) <> renderMarkdown ls
  | TL.isPrefixOf "- "  l  =
      let (items, rest) = span (TL.isPrefixOf "- ") (l:ls)
          lis = mconcat [ tag "li" (renderInline $ TL.drop 2 i) | i <- items ]
      in  "<ul>" <> lis <> "</ul>" <> renderMarkdown rest
  | TL.null (TL.strip l)   = renderMarkdown ls
  | otherwise               = tag "p" (renderInline l) <> renderMarkdown ls

renderInline :: Text -> Text
renderInline t
  | "**" `TL.isInfixOf` t = go t
  | otherwise = t
  where
    go txt = case TL.breakOn "**" txt of
      (before, rest) | TL.null rest -> before
      (before, rest) ->
        let rest'  = TL.drop 2 rest
            (bold, rest'') = TL.breakOn "**" rest'
        in  before <> "<strong>" <> bold <> "</strong>" <> go (TL.drop 2 rest'')

tag :: Text -> Text -> Text
tag t content = "<" <> t <> ">" <> content <> "</" <> t <> ">"

parseFrontMatter :: Text -> ([(Text,Text)], Text)
parseFrontMatter raw =
  let ls = TL.lines raw
  in case ls of
    ("---":rest) ->
      let (fm, body) = break (== "---") rest
          pairs = [ (k, TL.strip v)
                  | line <- fm
                  , let (k, v0) = TL.breakOn ":" line
                  , not (TL.null v0)
                  , let v = TL.drop 1 v0 ]
      in  (pairs, TL.unlines (drop 1 body))
    _ -> ([], raw)

lookupFM :: Text -> [(Text,Text)] -> Text -> Text
lookupFM key fm def = maybe def id (lookup key fm)

loadPost :: FilePath -> IO Post
loadPost path = do
  raw <- TLIO.readFile path
  let (fm, body) = parseFrontMatter raw
      slug       = TL.pack $ dropExtension $ takeFileName path
      title      = lookupFM "title"   fm "(Untitled)"
      date       = lookupFM "date"    fm ""
      excerpt    = lookupFM "excerpt" fm ""
      bodyHtml   = renderMarkdown (TL.lines body)
  return Post { postSlug    = slug
              , postTitle   = title
              , postDate    = date
              , postExcerpt = excerpt
              , postBody    = bodyHtml }

loadAllPosts :: IO [Post]
loadAllPosts = do
  files <- listDirectory "posts"
  let mds = filter (".md" `isSuffixOf`) files
  posts <- mapM (loadPost . ("posts" </>)) mds
  return $ sortBy (comparing (Down . postDate)) posts

layout :: Text -> Text -> Text
layout pageTitle content = TL.unlines
  [ "<!DOCTYPE html><html lang='en'><head>"
  , "<meta charset='UTF-8'/>"
  , "<meta name='viewport' content='width=device-width, initial-scale=1.0'/>"
  , "<title>" <> pageTitle <> " | Ana's Corner</title>"
  , "<link rel='preconnect' href='https://fonts.googleapis.com'/>"
  , "<link href='https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,400;0,700;1,400&family=DM+Sans:wght@300;400;500&display=swap' rel='stylesheet'/>"
  , "<link rel='stylesheet' href='/style.css'/>"
  , "<link rel='stylesheet' href='/blogs.css'/>"
  , "</head><body>"
  , "<nav>"
  , "  <a class='logo' href='/'>Ana's Corner</a>"
  , "  <ul class='nav-links'>"
  , "    <li><a href='/#hero'>Home</a></li>"
  , "    <li><a href='/#about'>About</a></li>"
  , "    <li><a href='/blog'>Journal</a></li>"
  , "  </ul>"
  , "</nav>"
  , "<main class='page-content'>"
  , content
  , "</main>"
  , "</body></html>"
  ]

blogIndexHtml :: [Post] -> Text
blogIndexHtml posts =
  let cards = mconcat (map postCard posts)
  in layout "Journal" $ TL.unlines
    [ "<div class='blog-header'>"
    , "  <p class='section-tag'>A bit of my writing</p>"
    , "  <h1 class='blog-title'>Ana's Journal</h1>"
    , "  <p class='blog-subtitle'>Daydreams, stories, and wandering thoughts.</p>"
    , "</div>"
    , "<div class='post-grid'>" <> cards <> "</div>"
    ]

postCard :: Post -> Text
postCard p = TL.unlines
  [ "<a class='post-card' href='/blog/" <> postSlug p <> "'>"
  , "  <span class='post-date'>" <> postDate p <> "</span>"
  , "  <h2 class='post-card-title'>" <> postTitle p <> "</h2>"
  , "  <p class='post-excerpt'>" <> postExcerpt p <> "</p>"
  , "  <span class='read-more'>Read more &rarr;</span>"
  , "</a>"
  ]

postPageHtml :: Post -> Text
postPageHtml p = layout (postTitle p) $ TL.unlines
  [ "<article class='post-article'>"
  , "  <header class='post-header'>"
  , "    <a class='back-link' href='/blog'>&larr; Back to Journal</a>"
  , "    <p class='post-date'>" <> postDate p <> "</p>"
  , "    <h1 class='post-title'>" <> postTitle p <> "</h1>"
  , "  </header>"
  , "  <div class='post-body'>" <> postBody p <> "</div>"
  , "</article>"
  ]

main :: IO ()
main = do
  portStr <- lookupEnv "PORT"
  let port = maybe 3300 read portStr
  putStrLn $ "Server running on port " ++ show port
  scotty port $ do

    middleware $ staticPolicy (addBase "static")

    get "/" $ do
      setHeader "Content-Type" "text/html; charset=utf-8"
      home <- liftIO $ TLIO.readFile "templates/index.html"
      html home

    get "/blog" $ do
      posts <- liftIO loadAllPosts
      setHeader "Content-Type" "text/html; charset=utf-8"
      html (blogIndexHtml posts)

    get "/blog/:slug" $ do
      slug  <- pathParam "slug"
      posts <- liftIO loadAllPosts
      case filter (\p -> postSlug p == slug) posts of
        (p:_) -> do
          setHeader "Content-Type" "text/html; charset=utf-8"
          html (postPageHtml p)
        [] -> do
          status $ toEnum 404
          html "<h1>Post not found</h1>"