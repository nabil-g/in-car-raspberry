module Main exposing (main)

import Browser exposing (application)
import Browser.Navigation as Nav exposing (Key)
import Model exposing (Clock, Model, PlayerStatus(..), Randomness(..), urlToRoute)
import Task
import Time exposing (now)
import Update exposing (Msg(..), subscriptions, update)
import Url exposing (Url, percentDecode)
import View exposing (view)


main : Program Int Model Msg
main =
    Browser.application { init = init, view = view, update = update, subscriptions = subscriptions, onUrlChange = UrlChanged, onUrlRequest = LinkClicked }


init : Int -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init a url key =
    ( { clock = Clock Time.utc (Time.millisToPosix 0)
      , routing =
            { key = key
            , currentPage = urlToRoute url
            }
      , player =
            { tracksList = []
            , status = Empty
            , loop = False
            , shuffle = Disabled
            , search = ""
            , fullscreenArtwork = Nothing
            }
      , windowHeight = a
      }
    , Cmd.batch
        [ Task.perform AdjustTimeZone Time.here
        , Task.perform Tick Time.now
        ]
    )
