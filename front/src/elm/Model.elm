module Model exposing (..)

import Json.Decode as D
import Json.Decode.Pipeline as P exposing (decode, optional, required)
import Time exposing (Time)


type alias Model =
    { tracksList : List ( Int, TrackInfo )
    , status : PlayerStatus
    , clock : Time
    , loop : Bool
    , shuffle : Randomness
    , search : String
    }


type Randomness
    = Enabled (List ( Int, TrackInfo ))
    | Disabled


type PlayerStatus
    = Playing PlayingPath
    | Paused PlayingPath
    | Loaded PlayingPath
    | Ended PlayingPath
    | Error Int
    | Empty
    | Unknown


type alias PlayingPath =
    String


type alias PlayerStatusEvent =
    { event : String
    , track : String
    , error : Maybe Int
    }


decodePlayerEvent : D.Value -> PlayerStatus
decodePlayerEvent val =
    let
        playerEventDecoder =
            P.decode PlayerStatusEvent
                |> P.required "event" D.string
                |> P.required "track" D.string
                |> P.optional "error " (D.nullable D.int) Nothing

        playerEventToStatus pse =
            case pse.event of
                "ended" ->
                    Ended pse.track

                "paused" ->
                    Paused pse.track

                "playing" ->
                    Playing pse.track

                "loaded" ->
                    Loaded pse.track

                "error" ->
                    Error <| Maybe.withDefault 0 <| pse.error

                _ ->
                    Empty
    in
    D.decodeValue playerEventDecoder val
        |> Result.map playerEventToStatus
        |> Result.withDefault Unknown


type alias TrackInfo =
    { relativePath : String
    , filename : String
    , title : Maybe String
    , artist : Maybe String
    , album : Maybe String
    , picture : Maybe Base64
    }


initTrackInfo : TrackInfo
initTrackInfo =
    { relativePath = ""
    , filename = ""
    , title = Nothing
    , artist = Nothing
    , album = Nothing
    , picture = Nothing
    }


type alias Base64 =
    String


trackDecoder : D.Decoder TrackInfo
trackDecoder =
    decode TrackInfo
        |> P.required "relativePath" D.string
        |> P.required "filename" D.string
        |> optional "title" (D.nullable D.string) Nothing
        |> optional "artist" (D.nullable D.string) Nothing
        |> optional "album" (D.nullable D.string) Nothing
        |> optional "picture" (D.nullable D.string) Nothing


initialModel : Model
initialModel =
    { tracksList = []
    , status = Empty
    , clock = 0
    , loop = False
    , shuffle = Disabled
    , search = ""
    }


socketPath : String
socketPath =
    "ws://localhost:8090"


getTrackInfo : List ( Int, TrackInfo ) -> PlayingPath -> TrackInfo
getTrackInfo ls tr =
    ls
        |> List.map (\tup -> Tuple.second tup)
        |> List.filter (\el -> el.relativePath == tr)
        |> List.head
        |> Maybe.withDefault initTrackInfo
