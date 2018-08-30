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
    { tracksList : List String
    , status : PlayerStatus
    , currentlyPlaying : Maybe String
    }


type PlayerStatus
    = Playing
    | Paused
    | Ended
    | Empty


type alias TrackInfo =
    { filename : String
    , title : Maybe String
    , artist : Maybe String
    , album : Maybe String
    }


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
    , currentlyPlaying = Nothing
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
    | PlayerEvent String


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

        PlayerEvent st ->
            let
                playerStatus =
                    case st of
                        "ended" ->
                            Ended

                        "playing" ->
                            Playing

                        "paused" ->
                            Paused

                        _ ->
                            Empty
            in
            ( { model | status = playerStatus }, Cmd.none )

        NewMessage mess ->
            let
                x =
                    case D.decodeString (D.list D.string) mess of
                        Ok ls ->
                            ls

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
                Playing ->
                    ( Pause, "Pause" )

                _ ->
                    ( Play, "Lire" )
    in
    div []
        [ ul [] (List.map viewTrack model.tracksList)
        , button [ onClick buttonMsg ] [ text buttonTxt ]
        ]


viewTrack : String -> Html Msg
viewTrack tr =
    li []
        [ a [ href "#", onClick <| PlayTrack tr ] [ text tr ]
        ]
