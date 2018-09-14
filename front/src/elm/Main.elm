module Main exposing (..)

import Html exposing (program)
import Model exposing (Model, initialModel)
import Task
import Time exposing (now)
import Update exposing (Msg(Tick), subscriptions, update)
import View exposing (view)


main : Program Never Model Msg
main =
    Html.program { init = ( initialModel, Task.perform Tick now ), view = view, update = update, subscriptions = subscriptions }
