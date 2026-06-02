{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric     #-}

module Main where

import Web.Scotty
import Data.Text.Lazy (Text)
import Data.Aeson (ToJSON, FromJSON)
import GHC.Generics (Generic)

-- ─── Example data type ────────────────────────────────────────────────────────

data User = User
  { userId   :: Int
  , userName :: String
  , userAge  :: Int
  } deriving (Show, Generic)

instance ToJSON   User
instance FromJSON User

-- Fake "database"
users :: [User]
users =
  [ User 1 "Alice" 30
  , User 2 "Bob"   25
  , User 3 "Carol" 28
  ]

-- ─── Routes ───────────────────────────────────────────────────────────────────

main :: IO ()
main = do
  putStrLn "Server running on http://localhost:3000"
  scotty 3000 $ do

    -- GET /
    -- Returns a plain HTML homepage
    get "/" $ do
      html "<h1>Welcome to Scotty!</h1><p>Try <a href='/hello/World'>/hello/World</a> or <a href='/users'>/users</a></p>"

    -- GET /hello/:name
    -- Returns a greeting as plain text
    get "/hello/:name" $ do
      name <- pathParam "name"   -- capture a URL segment
      text $ "Hello, " <> name <> "!"

    -- GET /greet?name=Alice
    -- Returns a greeting using a query parameter
    get "/greet" $ do
      name <- queryParam "name" :: ActionM Text
      text $ "Hey there, " <> name <> "!"

    -- GET /users
    -- Returns all users as JSON
    get "/users" $ do
      json users

    -- GET /users/:id
    -- Returns a single user by id, or 404
    get "/users/:id" $ do
      uid  <- pathParam "id" :: ActionM Int
      case filter (\u -> userId u == uid) users of
        (u:_) -> json u
        []    -> do
          status $ toEnum 404
          text "User not found"

    -- POST /echo
    -- Reads a plain-text body and echoes it back
    post "/echo" $ do
      body <- body
      raw body