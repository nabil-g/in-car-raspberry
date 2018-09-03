module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Json.Decode as D
import Json.Decode.Pipeline as P exposing (decode, optional, required)
import Ports
import WebSocket


-- APP


main : Program Never Model Msg
main =
    Html.program { init = ( initialModel, Cmd.none ), view = view, update = update, subscriptions = subscriptions }



-- MODEL


type alias Model =
    { tracksList : List ( Int, String )
    , status : PlayerStatus
    }


type PlayerStatus
    = Playing String
    | Paused String
    | Loaded String
    | Ended String
    | Empty
    | Unknown


type alias TrackInfo =
    { filename : String
    , title : Maybe String
    , artist : Maybe String
    , album : Maybe String
    }


type alias PlayerStatusEvent =
    { event : String, track : String }


decodePlayerEvent : D.Value -> PlayerStatus
decodePlayerEvent val =
    let
        playerEventDecoder =
            P.decode PlayerStatusEvent
                |> P.required "event" D.string
                |> P.required "track" D.string

        decodedValue =
            D.decodeValue playerEventDecoder val
    in
    Unknown


trackDecoder : D.Decoder TrackInfo
trackDecoder =
    decode TrackInfo
        |> P.required "filename" D.string
        |> optional "title" (D.nullable D.string) Nothing
        |> optional "artist" (D.nullable D.string) Nothing
        |> optional "album" (D.nullable D.string) Nothing


initialModel : Model
initialModel =
    { tracksList = []
    , status = Empty
    }


socketPath : String
socketPath =
    "ws://localhost:8082"



-- UPDATE


type Msg
    = NewMessage String
    | PlayTrack String
    | Play
    | Pause
    | PlayerEvent D.Value


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PlayTrack tr ->
            ( model, Ports.playTrack tr )

        Pause ->
            ( model, Ports.pause () )

        Play ->
            let
                cmd =
                    case model.status of
                        Empty ->
                            Cmd.none

                        _ ->
                            Ports.play ()
            in
            ( model, cmd )

        PlayerEvent value ->
            let
                playerStatus =
                    Unknown
            in
            ( { model | status = playerStatus }, Cmd.none )

        NewMessage mess ->
            let
                x =
                    case D.decodeString (D.list D.string) mess of
                        Ok ls ->
                            ls |> List.indexedMap (,)

                        Err ls ->
                            []
            in
            ( { model | tracksList = x }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions m =
    Sub.batch
        [ WebSocket.listen socketPath NewMessage
        , Ports.playerEvent PlayerEvent
        ]



-- VIEW


view : Model -> Html Msg
view model =
    let
        ( buttonMsg, buttonTxt ) =
            case model.status of
                Playing _ ->
                    ( Pause, "Pause" )

                _ ->
                    ( Play, "Lire" )
    in
    div []
        [ ul [] (List.map viewTrack model.tracksList)
        , button [ onClick buttonMsg ] [ text buttonTxt ]
        ]


viewTrack : ( Int, String ) -> Html Msg
viewTrack ( num, tr ) =
    li []
        [ a [ href "#", onClick <| PlayTrack tr ] [ text tr ]
        ]
