module Main exposing (main)

import Browser exposing (application)
import Model exposing (Model, initialModel)
import Task
import Time exposing (now)
import Update exposing (Msg(..), subscriptions, update)
import View exposing (view)


main : Program () Model Msg
main =
    Browser.application { init = \_ url key -> ( initialModel url key, getTimeZoneAndCurrentTime ), view = view, update = update, subscriptions = subscriptions, onUrlChange = UrlChanged, onUrlRequest = LinkClicked }


getTimeZoneAndCurrentTime : Cmd Msg
getTimeZoneAndCurrentTime =
    Cmd.batch
        [ Task.perform AdjustTimeZone Time.here
        , Task.perform Tick Time.now
        ]
