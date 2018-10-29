module Model exposing (Base64, Clock, Model, Player, PlayerStatus(..), PlayerStatusEvent, PlayingPath, Randomness(..), Route(..), Routing, TrackInfo, decodePlayerEvent, getTrackInfo, initTrackInfo, initialModel, parsePath, trackDecoder, urlToRoute, routeToUrlString)

import Browser.Navigation as Nav exposing (Key)
import Json.Decode as D exposing (succeed)
import Json.Decode.Pipeline as P exposing (optional, required)
import Time
import Url exposing (Url, percentDecode)


type alias Model =
    { clock : Clock
    , routing : Routing
    , player : Player
    }


type alias Player =
    { tracksList : List ( Int, TrackInfo )
    , status : PlayerStatus
    , loop : Bool
    , shuffle : Randomness
    , search : String
    }


type alias Routing =
    { key : Nav.Key
    , currentPage : Route
    }


type Route
    = Media
    | Settings
    | NotFound


type alias Clock =
    { timezone : Time.Zone
    , currentTime : Time.Posix
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
            D.succeed PlayerStatusEvent
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
    D.succeed TrackInfo
        |> P.required "relativePath" D.string
        |> P.required "filename" D.string
        |> optional "title" (D.nullable D.string) Nothing
        |> optional "artist" (D.nullable D.string) Nothing
        |> optional "album" (D.nullable D.string) Nothing
        |> optional "picture" (D.nullable D.string) Nothing


initialModel : Url.Url -> Nav.Key -> Model
initialModel url key =
    { clock = Clock Time.utc (Time.millisToPosix 0)
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
        }
    }


getTrackInfo : List ( Int, TrackInfo ) -> PlayingPath -> TrackInfo
getTrackInfo ls tr =
    ls
        |> List.map (\tup -> Tuple.second tup)
        |> List.filter (\el -> el.relativePath == tr)
        |> List.head
        |> Maybe.withDefault initTrackInfo


parsePath : String -> Maybe String
parsePath tr =
    tr
        |> String.dropLeft 22
        |> percentDecode


urlToRoute : Url -> Route
urlToRoute url =
    let
        path =
            Url.toString url
                |> parsePath
                |> Maybe.withDefault ""

        cleanedPath =
            if String.endsWith "#" path then
                String.dropRight 1 path

            else
                path
    in
    case cleanedPath of
        "media" ->
            Media

        "" ->
            Media

        "settings" ->
            Settings

        _ ->
            NotFound


routeToUrlString : Route -> String
routeToUrlString r =
    case r of
        Media ->
            "/media"

        Settings ->
            "/settings"

        NotFound ->
            "/"
