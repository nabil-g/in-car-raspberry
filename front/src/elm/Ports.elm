port module Ports exposing (..)

-- audio listeners


port playerEvent : (String -> msg) -> Sub msg



-- audio commands


port playTrack : String -> Cmd msg


port pause : () -> Cmd msg

port play : () -> Cmd msg
