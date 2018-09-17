module Update exposing (Msg(..), getAnotherTrack, getCurrentTrack, getTheFilteredList, getTheWorkingList, parseCurrentTrack, setAnotherTrack, setTheFirstTrack, shuffleTracksList, subscriptions, update)

import Browser
import Browser.Navigation as Nav exposing (load, pushUrl)
import Json.Decode as D
import Model exposing (Model, PlayerStatus(..), PlayingPath, Randomness(..), TrackInfo, decodePlayerEvent, initTrackInfo, trackDecoder)
import Ports
import Random exposing (generate)
import Random.List exposing (shuffle)
import Time
import Url exposing (Url, percentDecode)


type Msg
    = IncomingSocketMsg String
    | SetTrack String
    | Play
    | Pause
    | Previous
    | Next
    | PlayerEvent D.Value
    | Tick Time.Posix
    | AdjustTimeZone Time.Zone
    | ToggleLoop Bool
    | ToggleShuffle Bool
    | GotAShuffleList (List TrackInfo)
    | Search String
    | UrlChanged Url.Url
    | LinkClicked Browser.UrlRequest


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.appKey (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            let
                x =
                    Debug.log "xxx" <| Url.toString url
            in
            ( model, Cmd.none )

        Search s ->
            ( { model | search = String.toLower s }, Cmd.none )

        GotAShuffleList ls ->
            ( { model | shuffle = Enabled <| List.indexedMap (\a b -> ( a, b )) ls }, Cmd.none )

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
                            ls |> List.indexedMap (\a b -> ( a, b ))

                        Err ls ->
                            []
            in
            ( { model | tracksList = x }, Cmd.none )

        Tick time ->
            let
                clock =
                    model.clock
            in
            { clock | currentTime = time }
                |> (\c -> ( { model | clock = c }, Cmd.none ))

        AdjustTimeZone zone ->
            let
                clock =
                    model.clock
            in
            { clock | timezone = zone }
                |> (\c -> ( { model | clock = c }, Cmd.none ))


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
            modBy (List.length ls) (curindex + direction)
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
        |> percentDecode


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
        |> List.indexedMap (\a b -> ( a, b ))


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
        [ Ports.incomingSocketMsg IncomingSocketMsg
        , Ports.playerEvent PlayerEvent
        , Time.every 60000 Tick
        ]
