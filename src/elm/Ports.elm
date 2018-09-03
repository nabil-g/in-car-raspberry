port module Ports exposing (incomingSocketMsg, pause, play, playerEvent, setTrack, timeUpdate)

import Json.Decode exposing (Value)



-- incoming


port playerEvent : (Value -> msg) -> Sub msg


port timeUpdate : (Float -> msg) -> Sub msg


port incomingSocketMsg : (String -> msg) -> Sub msg



-- outgoing


port setTrack : String -> Cmd msg


port pause : () -> Cmd msg


port play : () -> Cmd msg
