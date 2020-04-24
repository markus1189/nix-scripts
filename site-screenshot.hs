#!/usr/bin/env nix-shell
#!nix-shell site-screenshot.nix --pure -i runhaskell
{-# OPTIONS_GHC -Wall #-}
{-# LANGUAGE OverloadedStrings #-}
module Main where

import Control.Monad (unless, when)
import Control.Monad.IO.Class (liftIO)
import Data.Function (fix)
import Data.List (isInfixOf)
import System.Environment (getArgs)
import System.IO (Handle, hGetLine)
import System.IO.Temp (emptySystemTempFile)
import System.Process.Typed (withProcessTerm, shell, setStderr, getStderr, createPipe, ProcessConfig)
import Test.WebDriver
import Control.Concurrent.Async (forConcurrently_)

chromeConfig :: WDConfig
chromeConfig = useBrowser browserConfig defaultConfig
  where browserConfig = chrome { chromeOptions = ["--headless", "--window-size=3840,2160"] }

seleniumServerProcess :: ProcessConfig () () Handle
seleniumServerProcess = setStderr createPipe $
  shell "java -jar $seleniumServerJar"

main :: IO ()
main = do
  args <- getArgs
  when (null args) $ putStrLn "No urls given!"
  unless (null args) $
    withRunningSeleniumServer $ do
      forConcurrently_ args $ \url -> do
        runSession chromeConfig . finallyClose $ do
          openPage url
          file <- liftIO $ emptySystemTempFile "site-screenshot.png"
          saveScreenshot file
          liftIO . putStrLn $ url <> "," <> file

withRunningSeleniumServer :: IO a -> IO a
withRunningSeleniumServer act = withProcessTerm seleniumServerProcess $ \seleniumServer -> do
  fix $ \loop -> do
    line <- hGetLine (getStderr seleniumServer)
    unless ("Selenium Server is up and running" `isInfixOf` line) loop
  act
