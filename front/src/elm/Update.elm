module Update exposing (..)

import Http exposing (decodeUri)
import Json.Decode as D
import Model exposing (Model, PlayerStatus(..), PlayingPath, Randomness(..), TrackInfo, decodePlayerEvent, initTrackInfo, socketPath, trackDecoder)
import Ports
import Random exposing (generate)
import Random.List exposing (shuffle)
import Time exposing (Time, every, minute)
import WebSocket


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
            ( { model | search = String.toLower s }, Cmd.none )

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
                                |> getTheFilteredList model.search

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
                                |> getTheFilteredList model.search

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
                        |> getTheFilteredList model.search

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


getTheFilteredList : String -> List ( Int, TrackInfo ) -> List ( Int, TrackInfo )
getTheFilteredList query ls =
    let
        filteringFunc el =
            (String.contains query <| String.toLower el.filename)
                || (String.contains query <| String.toLower <| Maybe.withDefault "" el.title)
                || (String.contains query <| String.toLower <| Maybe.withDefault "" el.artist)
                || (String.contains query <| String.toLower <| Maybe.withDefault "" el.album)
    in
    ls
        |> List.map (\element -> Tuple.second element)
        |> List.filter filteringFunc
        |> List.indexedMap (,)


getTheWorkingList : Model -> List ( Int, TrackInfo )
getTheWorkingList model =
    case model.shuffle of
        Enabled ls ->
            ls

        Disabled ->
            model.tracksList


shuffleTracksList : List ( Int, TrackInfo ) -> Cmd Msg
shuffleTracksList ls =
    ls
        |> List.map (\el -> Tuple.second el)
        |> shuffle
        |> generate GotAShuffleList


subscriptions : Model -> Sub Msg
subscriptions m =
    Sub.batch
        [ WebSocket.listen socketPath IncomingSocketMsg
        , Ports.playerEvent PlayerEvent
        , every minute Tick
        ]
