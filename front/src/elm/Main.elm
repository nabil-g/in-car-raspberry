module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Html.Keyed as HK
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
    = Playing TrackData
    | Paused TrackData
    | Loaded TrackData
    | Ended TrackData
    | Empty
    | Unknown


type alias TrackData =
    { track : String
    }


type alias PlayerStatusEvent =
    { event : String
    , track : String
    }


decodePlayerEvent : D.Value -> PlayerStatus
decodePlayerEvent val =
    let
        playerEventDecoder =
            P.decode PlayerStatusEvent
                |> P.required "event" D.string
                |> P.required "track" D.string

        playerEventToStatus pse =
            case pse.event of
                "ended" ->
                    Ended <| TrackData pse.track

                "paused" ->
                    Paused <| TrackData pse.track

                "playing" ->
                    Playing <| TrackData pse.track

                "loaded" ->
                    Loaded <| TrackData pse.track

                _ ->
                    Empty
    in
    D.decodeValue playerEventDecoder val
        |> Result.map playerEventToStatus
        |> Result.withDefault Unknown



--type alias TrackInfo =
--    { filename : String
--    , title : Maybe String
--    , artist : Maybe String
--    , album : Maybe String
--    }
--trackDecoder : D.Decoder TrackInfo
--trackDecoder =
--    decode TrackInfo
--        |> P.required "filename" D.string
--        |> optional "title" (D.nullable D.string) Nothing
--        |> optional "artist" (D.nullable D.string) Nothing
--        |> optional "album" (D.nullable D.string) Nothing


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
    | SetTrack String
    | Play
    | Pause
    | Previous
    | Next
    | PlayerEvent D.Value


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetTrack tr ->
            ( model, Ports.setTrack tr )

        Pause ->
            ( model, Ports.pause () )

        Previous ->
            case model.status of
                Playing tr ->
                    let
                        cmd =
                            case model.tracksList of
                                [] ->
                                    Cmd.none

                                _ ->
                                    model.tracksList
                                        |> getTrackIndex tr.track
                                        |> getAnotherTrack -1 model.tracksList
                                        |> Ports.setTrack
                    in
                    ( model, cmd )

                _ ->
                    ( model, Cmd.none )

        Next ->
            case model.status of
                Playing tr ->
                    let
                        cmd =
                            case model.tracksList of
                                [] ->
                                    Cmd.none

                                _ ->
                                    model.tracksList
                                        |> getTrackIndex tr.track
                                        |> getAnotherTrack 1 model.tracksList
                                        |> Ports.setTrack
                    in
                    ( model, cmd )

                _ ->
                    ( model, Cmd.none )

        Play ->
            let
                cmd =
                    case model.status of
                        Empty ->
                            if model.tracksList == [] then
                                Cmd.none
                            else
                                model.tracksList
                                    |> List.head
                                    |> Maybe.withDefault ( 0, "" )
                                    |> Tuple.second
                                    |> Ports.setTrack

                        _ ->
                            Ports.play ()
            in
            ( model, cmd )

        PlayerEvent pe ->
            let
                playerStatus =
                    decodePlayerEvent pe

                cmd =
                    case playerStatus of
                        Loaded tr ->
                            Ports.play ()

                        _ ->
                            Cmd.none
            in
            ( { model | status = playerStatus }, cmd )

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


getTrackIndex : String -> List ( Int, String ) -> Int
getTrackIndex st ls =
    List.filter (\tup -> Tuple.second tup == st) ls
        |> List.map (\tup -> Tuple.first tup)
        |> List.head
        |> Maybe.withDefault 0


getAnotherTrack : Int -> List ( Int, String ) -> Int -> String
getAnotherTrack direction ls curindex =
    let
        nextTrackIndex =
            (curindex + direction) % List.length ls
    in
    ls
        |> List.filter (\tup -> Tuple.first tup == nextTrackIndex)
        |> List.map (\tup -> Tuple.second tup)
        |> List.head
        |> Maybe.withDefault ""



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
    div []
        [ HK.ul []
            (List.map viewTrack model.tracksList)
        , viewPlayerToolbar model
        ]


viewPlayerToolbar : Model -> Html Msg
viewPlayerToolbar model =
    let
        status =
            case model.status of
                Playing tr ->
                    p [] [ text tr.track ]

                Paused tr ->
                    p [] [ text tr.track ]

                Loaded tr ->
                    p [] [ text tr.track ]

                Ended tr ->
                    p [] [ text tr.track ]

                _ ->
                    text ""

        ( buttonMsg, buttonTxt ) =
            case model.status of
                Playing tr ->
                    ( Pause, "Pause" )

                _ ->
                    ( Play, "Lire" )
    in
    div []
        [ button [ onClick Next ] [ text "Prev" ]
        , button [ onClick buttonMsg ] [ text buttonTxt ]
        , button [ onClick Previous ] [ text "Suiv" ]
        , status
        ]


viewTrack : ( Int, String ) -> ( String, Html Msg )
viewTrack ( num, tr ) =
    ( toString num
    , li []
        [ a [ href "#", onClick <| SetTrack tr ] [ text tr ]
        ]
    )
