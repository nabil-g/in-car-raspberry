module Main exposing (main)

import Browser exposing (document)
import Model exposing (Model, initialModel)
import Task
import Time exposing (now)
import Update exposing (Msg(..), subscriptions, update)
import View exposing (view)


main : Program () Model Msg
main =
    Browser.document { init = \_ -> ( initialModel, getTimeZoneAndCurrentTime ), view = view, update = update, subscriptions = subscriptions }


getTimeZoneAndCurrentTime : Cmd Msg
getTimeZoneAndCurrentTime =
    Cmd.batch
        [ Task.perform AdjustTimeZone Time.here
        , Task.perform Tick Time.now
        ]
