module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Html.Keyed as HK
import Http exposing (decodeUri)
import Json.Decode as D
import Json.Decode.Pipeline as P exposing (decode, optional, required)
import Ports
import Random exposing (generate)
import Random.List exposing (shuffle)
import Task
import Time exposing (Time, every, inHours, inMinutes, minute, now)
import Time.Format exposing (format)
import WebSocket


-- APP


main : Program Never Model Msg
main =
    Html.program { init = ( initialModel, Task.perform Tick now ), view = view, update = update, subscriptions = subscriptions }



-- MODEL


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



-- UPDATE


type Msg
    = IncomingSocketMsg String
    | SetTrack String
    | Play
    | Pause
    | Previous
    | Next
    | PlayerEvent D.Value
    | Tick Time
    | ToggleLoop Bool
    | ToggleShuffle Bool
    | GotAShuffleList (List TrackInfo)
    | Search String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Search s ->
            ( { model | search = s }, Cmd.none )

        GotAShuffleList ls ->
            ( { model | shuffle = Enabled <| List.indexedMap (,) ls }, Cmd.none )

        ToggleLoop b ->
            ( { model | loop = b }, Cmd.none )

        ToggleShuffle b ->
            if b then
                ( model, shuffleTracksList model.tracksList )
            else
                ( { model | shuffle = Disabled }, Cmd.none )

        SetTrack tr ->
            ( model, Ports.setTrack tr )

        Pause ->
            ( model, Ports.pause () )

        Previous ->
            case getCurrentTrack model.status of
                Just tr ->
                    let
                        ls =
                            getTheWorkingList model

                        cmd =
                            setAnotherTrack ls -1 tr
                    in
                    ( model, cmd )

                Nothing ->
                    ( model, Cmd.none )

        Next ->
            case getCurrentTrack model.status of
                Just tr ->
                    let
                        ls =
                            getTheWorkingList model

                        cmd =
                            setAnotherTrack ls 1 tr
                    in
                    ( model, cmd )

                Nothing ->
                    ( model, Cmd.none )

        Play ->
            let
                cmd =
                    case model.status of
                        Empty ->
                            setTheFirstTrack model

                        Error int ->
                            Cmd.none

                        _ ->
                            Ports.play ()
            in
            ( model, cmd )

        PlayerEvent pe ->
            let
                playerStatus =
                    decodePlayerEvent pe

                ls =
                    getTheWorkingList model

                cmd =
                    case playerStatus of
                        Loaded tr ->
                            Ports.play ()

                        Ended tr ->
                            if ls /= [] then
                                if model.loop then
                                    setAnotherTrack ls 0 tr
                                else
                                    setAnotherTrack ls 1 tr
                            else
                                Cmd.none

                        _ ->
                            Cmd.none
            in
            ( { model | status = playerStatus }, cmd )

        IncomingSocketMsg mess ->
            let
                x =
                    case D.decodeString (D.list trackDecoder) mess of
                        Ok ls ->
                            ls |> List.indexedMap (,)

                        Err ls ->
                            []
            in
            ( { model | tracksList = x }, Cmd.none )

        Tick time ->
            ( { model | clock = time }, Cmd.none )


getCurrentTrack : PlayerStatus -> Maybe PlayingPath
getCurrentTrack ps =
    case ps of
        Playing tr ->
            Just tr

        Paused tr ->
            Just tr

        Loaded tr ->
            Just tr

        Ended tr ->
            Just tr

        _ ->
            Nothing


setAnotherTrack : List ( Int, TrackInfo ) -> Int -> String -> Cmd Msg
setAnotherTrack ls direction tr =
    if List.length ls > 1 then
        ls
            |> getAnotherTrack tr direction
            |> Debug.log "new track is : "
            |> Ports.setTrack
    else
        Cmd.none


getAnotherTrack : String -> Int -> List ( Int, TrackInfo ) -> String
getAnotherTrack tr direction ls =
    let
        parsedTr =
            Maybe.withDefault "" <| parseCurrentTrack tr

        curindex =
            List.filter (\tup -> .relativePath (Tuple.second tup) == parsedTr) ls
                |> List.map (\tup -> Tuple.first tup)
                |> List.head
                |> Maybe.withDefault 0

        nextTrackIndex =
            (curindex + direction) % List.length ls
    in
    ls
        |> List.filter (\tup -> Tuple.first tup == nextTrackIndex)
        |> List.map (\tup -> Tuple.second tup)
        |> List.head
        |> Maybe.withDefault initTrackInfo
        |> .relativePath


setTheFirstTrack : Model -> Cmd Msg
setTheFirstTrack model =
    if model.tracksList == [] then
        Cmd.none
    else
        model.tracksList
            |> List.head
            |> Maybe.withDefault ( 0, initTrackInfo )
            |> Tuple.second
            |> .relativePath
            |> Ports.setTrack


parseCurrentTrack : String -> Maybe String
parseCurrentTrack tr =
    tr
        |> String.dropLeft 22
        |> decodeUri


getTheWorkingList : Model -> List ( Int, TrackInfo )
getTheWorkingList model =
    let
        list =
            case model.shuffle of
                Enabled ls ->
                    ls

                Disabled ->
                    model.tracksList
    in
    list
        |> List.filter (\el -> Tuple.second el)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions m =
    Sub.batch
        [ WebSocket.listen socketPath IncomingSocketMsg
        , Ports.playerEvent PlayerEvent
        , every minute Tick
        ]



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ input [ type_ "text", placeholder "Rechercher", onInput Search ] []
        , HK.ul []
            (List.map viewTrack model.tracksList)
        , viewPlayerToolbar model
        , div []
            [ text <| format "%H" model.clock
            , text <| ":"
            , text <| format "%M" model.clock
            ]
        ]


viewTrack : ( Int, TrackInfo ) -> ( String, Html Msg )
viewTrack ( num, tr ) =
    ( toString num
    , li []
        [ a [ href "#", onClick <| SetTrack tr.relativePath ] [ text tr.filename ]
        ]
    )


viewPlayerToolbar : Model -> Html Msg
viewPlayerToolbar model =
    let
        status =
            case getCurrentTrack model.status of
                Just tr ->
                    tr
                        |> parseCurrentTrack
                        |> Maybe.withDefault ""
                        |> getTrackInfo model.tracksList
                        |> displayCurrentTrack

                Nothing ->
                    text ""

        ( buttonMsg, buttonTxt ) =
            case model.status of
                Playing tr ->
                    ( Pause, "Pause" )

                _ ->
                    ( Play, "Lire" )

        disableOnError =
            case model.status of
                Error _ ->
                    True

                _ ->
                    False

        ( shuffleMsg, shuffleTxt ) =
            if model.shuffle == Disabled then
                ( True, "Activer le mode aléatoire" )
            else
                ( False, "Désactiver le mode aléatoire" )
    in
    div []
        [ button [ onClick Previous, disabled disableOnError ] [ text "Prev" ]
        , button [ onClick buttonMsg, disabled disableOnError ] [ text buttonTxt ]
        , button [ onClick Next, disabled disableOnError ] [ text "Suiv" ]
        , button [ onClick <| ToggleLoop <| not model.loop, disabled disableOnError, style [ ( "margin-left", "10px" ) ] ]
            [ if model.loop then
                text "Désactiver la répétition"
              else
                text "Activer la répétition"
            ]
        , button [ onClick <| ToggleShuffle shuffleMsg, disabled disableOnError ]
            [ text shuffleTxt
            ]
        , status
        ]


shuffleTracksList : List ( Int, TrackInfo ) -> Cmd Msg
shuffleTracksList ls =
    ls
        |> List.map (\el -> Tuple.second el)
        |> shuffle
        |> generate GotAShuffleList


displayCurrentTrack : TrackInfo -> Html Msg
displayCurrentTrack tri =
    div []
        [ p [] [ text <| Maybe.withDefault tri.filename tri.title ]
        , p [] [ text <| Maybe.withDefault "" tri.artist ]
        , p [] [ text <| Maybe.withDefault "" tri.album ]
        , case tri.picture of
            Just pic ->
                img [ src <| "data:image/png;base64," ++ pic ] []

            Nothing ->
                text ""
        ]


getTrackInfo : List ( Int, TrackInfo ) -> PlayingPath -> TrackInfo
getTrackInfo ls tr =
    ls
        |> List.filter (\tup -> .relativePath (Tuple.second tup) == tr)
        |> List.map (\tup -> Tuple.second tup)
        |> List.head
        |> Maybe.withDefault initTrackInfo
