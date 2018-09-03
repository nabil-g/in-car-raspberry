port module Ports exposing (..)

import Json.Decode exposing (Value)


-- audio listeners


port playerEvent : (Value -> msg) -> Sub msg



-- audio commands


port playTrack : String -> Cmd msg


port pause : () -> Cmd msg


port play : () -> Cmd msg
