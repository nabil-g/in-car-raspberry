port module Ports exposing (enhancedTrack, getMetadata, incomingSocketMsg, pause, play, playerEvent, setTrack,scrollToTrack)

import Json.Decode exposing (Value)
import Model exposing (TrackInfo)



-- incoming


port playerEvent : (Value -> msg) -> Sub msg


port incomingSocketMsg : (String -> msg) -> Sub msg


port enhancedTrack : (Value -> msg) -> Sub msg



-- outgoing


port setTrack : String -> Cmd msg


port pause : () -> Cmd msg


port play : () -> Cmd msg


port getMetadata : TrackInfo -> Cmd msg


port scrollToTrack : String -> Cmd msg
