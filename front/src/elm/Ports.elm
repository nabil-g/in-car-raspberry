port module Ports exposing (..)

-- audio commands


port playTrack : String -> Cmd msg


port togglePause : Bool -> Cmd msg



-- audio listeners
