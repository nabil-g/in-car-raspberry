port module Ports exposing (..)

import Json.Decode exposing (Value)


-- audio listeners


port playerEvent : (Value -> msg) -> Sub msg



-- audio commands


port setTrack : String -> Cmd msg


port pause : () -> Cmd msg


port play : () -> Cmd msg
