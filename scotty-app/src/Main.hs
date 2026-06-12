{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE OverloadedStrings #-}

module Main where

import Web.Scotty                   
import Network.Wai.Middleware.Static (staticPolicy, addBase)
import Network.Wai.Handler.Warp (setHost, setPort, defaultSettings)
import Data.Text.Lazy (Text)
import qualified Data.Text.Lazy as TL
import qualified Data.Text.Lazy.IO as TLIO
import Data.List (sortBy, isPrefixOf, isSuffixOf)
import Data.Ord (comparing, Down(..))
import System.Directory (listDirectory, getCurrentDirectory)
import System.FilePath ((</>), dropExtension, takeFileName)
import Prelude hiding (readFile)
import System.Environment (lookupEnv)
import System.IO (hSetBuffering, stdout, stderr, BufferMode(..))
import System.IO (hSetEncoding, utf8, openFile, IOMode(..))
import Control.Exception (try, evaluate, SomeException)

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
  handle <- openFile path ReadMode
  hSetEncoding handle utf8
  raw <- TLIO.hGetContents handle
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
  let dir = "posts"
  putStrLn $ "Looking for posts in: " ++ dir
  files <- listDirectory dir
  putStrLn $ "Found files: " ++ show files
  let mds = filter (".md" `isSuffixOf`) files
  posts <- mapM loadAndLog mds
  return $ sortBy (comparing (Down . postDate)) posts
  where
    loadAndLog f = do
      putStrLn $ "Loading post: " ++ f
      p <- loadPost ("posts" </> f)
      putStrLn $ "Loaded: " ++ show (postTitle p)
      return p

layout :: Text -> Text -> Text
layout pageTitle content =
  "<!DOCTYPE html><html lang='en'><head>" <>
  "<meta charset='UTF-8'/>" <>
  "<meta name='viewport' content='width=device-width, initial-scale=1.0'/>" <>
  "<title>" <> pageTitle <> " | Ana's Corner</title>" <>
  "<link rel='preconnect' href='https://fonts.googleapis.com'/>" <>
  "<link href='https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,400;0,700;1,400&family=DM+Sans:wght@300;400;500&display=swap' rel='stylesheet'/>" <>
  "<link rel='stylesheet' href='/style.css'/>" <>
  "<link rel='stylesheet' href='/blogs.css'/>" <>
  "</head><body>" <>
  "<nav>" <>
  "<a class='logo' href='/'>Ana's Corner</a>" <>
  "<ul class='nav-links'>" <>
  "<li><a href='/#hero'>Home</a></li>" <>
  "<li><a href='/#about'>About</a></li>" <>
  "<li><a href='/blog'>Journals</a></li>" <>
  "</ul></nav>" <>
  "<main class='page-content'>" <>
  content <>
  "</main></body></html>"

blogIndexHtml :: [Post] -> Text
blogIndexHtml posts =
  layout "Journal" $
  "<div class='blog-header'>" <>
  "<p class='section-tag'>A bit of my writing</p>" <>
  "<h1 class='blog-title'>Ana's Journal</h1>" <>
  "<p class='blog-subtitle'>Daydreams, stories, and wandering thoughts.</p>" <>
  "</div>" <>
  "<div class='post-grid'>" <> mconcat (map postCard posts) <> "</div>"

postCard :: Post -> Text
postCard p =
  "<a class='post-card' href='/blog/" <> postSlug p <> "'>" <>
  "<span class='post-date'>" <> postDate p <> "</span>" <>
  "<h2 class='post-card-title'>" <> postTitle p <> "</h2>" <>
  "<p class='post-excerpt'>" <> postExcerpt p <> "</p>" <>
  "<span class='read-more'>Read more &rarr;</span>" <>
  "</a>"

postPageHtml :: Post -> Text
postPageHtml p =
  layout (postTitle p) $
  "<article class='post-article'>" <>
  "<header class='post-header'>" <>
  "<a class='back-link' href='/blog'>&larr; Back to Journal</a>" <>
  "<p class='post-date'>" <> postDate p <> "</p>" <>
  "<h1 class='post-title'>" <> postTitle p <> "</h1>" <>
  "</header>" <>
  "<div class='post-body'>" <> postBody p <> "</div>" <>
  "</article>"

main :: IO ()
main = do
  hSetBuffering stdout NoBuffering
  hSetBuffering stderr NoBuffering
  cwd <- getCurrentDirectory
  putStrLn $ "Working directory: " ++ cwd
  portStr <- lookupEnv "PORT"
  let port = case portStr of
               Just p  -> read p
               Nothing -> 3300
  putStrLn $ "Server running on port " ++ show port

  posts <- loadAllPosts   
  putStrLn $ "Loaded " ++ show (length posts) ++ " posts"

  let warpSettings  = setPort port $ setHost "0.0.0.0" defaultSettings
      scottyOptions = defaultOptions { verbose = 1, settings = warpSettings }

  scottyOpts scottyOptions $ do
    middleware $ staticPolicy (addBase "static")

    get "/" $ do
      setHeader "Content-Type" "text/html; charset=utf-8"
      home <- liftIO $ TLIO.readFile "templates/index.html"
      html home

    get "/blog" $ do
      liftIO $ putStrLn "Hit /blog route"
      setHeader "Content-Type" "text/html; charset=utf-8"
      result <- liftIO $ try (evaluate (blogIndexHtml posts)) :: ActionM (Either SomeException Text)
      case result of
        Left err -> do
          liftIO $ putStrLn $ "ERROR rendering blog: " ++ show err
          html "<h1>Error rendering page</h1>"
        Right page -> do
          let !len = TL.length page
          liftIO $ putStrLn $ "Response length: " ++ show len
          html page

    get "/blog/:slug" $ do
      slug <- pathParam "slug"
      liftIO $ putStrLn $ "slug: " ++ show slug

      case filter (\p -> postSlug p == slug) posts of  
        (p:_) -> do
          setHeader "Content-Type" "text/html; charset=utf-8"
          html (postPageHtml p)
        [] -> do
          status $ toEnum 404
          html "<h1>Post not found</h1>"