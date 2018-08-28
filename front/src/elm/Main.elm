module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Json.Decode as D
import Json.Decode.Pipeline as P exposing (decode, optional, required)
import WebSocket
import Ports


-- APP


main : Program Never Model Msg
main =
    Html.program { init = ( initialModel, Cmd.none ), view = view, update = update, subscriptions = subscriptions }



-- MODEL


type alias Model =
    { tracksList : List String
    , playing : Bool
    , currentlyPlaying : Maybe String
    }


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
    , playing = False
    , currentlyPlaying = Nothing
    }


socketPath : String
socketPath =
    "ws://localhost:8082"



-- UPDATE


type Msg
    = NoOp
    | NewMessage String
    | PlayTrack String
    | Play
    | Pause
    | PlayerEvent String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        PlayTrack tr ->
            ( model, Ports.playTrack tr )

        Pause ->
            ( model, Ports.pause () )

        Play ->
            ( model, Ports.play () )

        PlayerEvent st ->
            let
                playingStatus =
                    case st of
                        "ended" ->
                            False

                        "playing" ->
                            True

                        "paused" ->
                            False

                        _ ->
                            False
            in
                ( { model | playing = playingStatus }, Cmd.none )

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
            case model.playing of
                False ->
                    ( Play, "Lire" )

                True ->
                    ( Pause, "Pause" )
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
