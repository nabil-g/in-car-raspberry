module Update exposing (Msg(..), getAnotherTrack, getCurrentTrack, getTheFilteredList, getTheWorkingList, getTrackInfoFromStatus, setAnotherTrack, setTheFirstTrack, shuffleTracksList, subscriptions, trackScrollId, update)

import Browser
import Browser.Navigation as Nav exposing (load, pushUrl)
import Json.Decode as D
import Model exposing (Model, Player, PlayerStatus(..), PlayingPath, Randomness(..), Route(..), Routing, TrackInfo, decodePlayerEvent, initTrackInfo, parsePath, trackDecoder, urlToRoute)
import Ports
import Random exposing (generate)
import Random.List exposing (shuffle)
import Time
import Url exposing (Url)


type Msg
    = IncomingSocketMsg String
    | SetTrack TrackInfo
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
    | GotAnEnhancedTrack D.Value
    | Search String
    | UrlChanged Url.Url
    | LinkClicked Browser.UrlRequest
    | ClearSearch
    | CloseArtwork
    | DisplayArtwork String
    | ScrollToTrack String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ScrollToTrack s ->
            ( model, Ports.scrollToTrack <| Debug.log "xx" s )

        DisplayArtwork s ->
            model.player
                |> (\p -> { p | fullscreenArtwork = Just s })
                |> (\p -> ( { model | player = p }, Cmd.none ))

        CloseArtwork ->
            model.player
                |> (\p -> { p | fullscreenArtwork = Nothing })
                |> (\p -> ( { model | player = p }, Cmd.none ))

        ClearSearch ->
            let
                updatedPlayer =
                    model.player
                        |> (\player -> { player | search = "" })
            in
            ( { model | player = updatedPlayer }, Cmd.none )

        GotAnEnhancedTrack val ->
            let
                newTracksList =
                    case D.decodeValue trackDecoder val of
                        Ok tr ->
                            model.player.tracksList
                                |> List.map
                                    (\( a1, a2 ) ->
                                        if a2.filename == tr.filename && a2.relativePath == tr.relativePath then
                                            ( a1, tr )

                                        else
                                            ( a1, a2 )
                                    )

                        Err e ->
                            model.player.tracksList

                updatedPlayer =
                    model.player
                        |> (\player -> { player | tracksList = newTracksList })
            in
            ( { model | player = updatedPlayer }, Cmd.none )

        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.routing.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            let
                newRoute =
                    urlToRoute url

                newRouting =
                    model.routing
                        |> (\routing -> { routing | currentPage = newRoute })
            in
            ( { model | routing = newRouting }, Cmd.none )

        Search s ->
            let
                updatedPlayer =
                    model.player
                        |> (\player -> { player | search = String.toLower s })
            in
            ( { model | player = updatedPlayer }, Cmd.none )

        GotAShuffleList ls ->
            let
                updatedPlayer =
                    model.player
                        |> (\player -> { player | shuffle = Enabled <| List.indexedMap (\a b -> ( a, b )) ls })
            in
            ( { model | player = updatedPlayer }, Cmd.none )

        ToggleLoop b ->
            let
                updatedPlayer =
                    model.player
                        |> (\player -> { player | loop = b })
            in
            ( { model | player = updatedPlayer }, Cmd.none )

        ToggleShuffle b ->
            if b then
                ( model, shuffleTracksList model.player.tracksList )

            else
                let
                    updatedPlayer =
                        model.player
                            |> (\player -> { player | shuffle = Disabled })
                in
                ( { model | player = updatedPlayer }, Cmd.none )

        SetTrack tr ->
            ( model, Cmd.batch [ setTrack tr ] )

        Pause ->
            ( model, Ports.pause () )

        Previous ->
            case getCurrentTrack model.player.status of
                Just tr ->
                    let
                        ls =
                            getTheWorkingList model.player
                                |> getTheFilteredList model.player.search

                        cmd =
                            setAnotherTrack ls -1 tr
                    in
                    ( model, cmd )

                Nothing ->
                    ( model, Cmd.none )

        Next ->
            case getCurrentTrack model.player.status of
                Just tr ->
                    let
                        ls =
                            getTheWorkingList model.player
                                |> getTheFilteredList model.player.search

                        cmd =
                            setAnotherTrack ls 1 tr
                    in
                    ( model, cmd )

                Nothing ->
                    ( model, Cmd.none )

        Play ->
            let
                cmd =
                    case model.player.status of
                        Empty ->
                            setTheFirstTrack model.player

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
                    getTheWorkingList model.player
                        |> getTheFilteredList model.player.search

                cmd =
                    case playerStatus of
                        Loaded tr ->
                            Ports.play ()

                        Ended tr ->
                            if ls /= [] then
                                if model.player.loop then
                                    setAnotherTrack ls 0 tr

                                else
                                    setAnotherTrack ls 1 tr

                            else
                                Cmd.none

                        _ ->
                            Cmd.none

                updatedPlayer =
                    model.player
                        |> (\player -> { player | status = playerStatus })
            in
            ( { model | player = updatedPlayer }, cmd )

        IncomingSocketMsg mess ->
            let
                x =
                    case D.decodeString (D.list trackDecoder) mess of
                        Ok ls ->
                            ls |> List.indexedMap (\a b -> ( a, b ))

                        Err ls ->
                            []

                updatedPlayer =
                    model.player
                        |> (\player -> { player | tracksList = x })
            in
            ( { model | player = updatedPlayer }, Cmd.none )

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
            |> setTrack

    else
        Cmd.none


getAnotherTrack : String -> Int -> List ( Int, TrackInfo ) -> TrackInfo
getAnotherTrack tr direction ls =
    let
        parsedTr =
            Maybe.withDefault "" <| parsePath tr

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


setTheFirstTrack : Player -> Cmd Msg
setTheFirstTrack player =
    if player.tracksList == [] then
        Cmd.none

    else
        player.tracksList
            |> List.head
            |> Maybe.withDefault ( 0, initTrackInfo )
            |> Tuple.second
            |> setTrack


setTrack : TrackInfo -> Cmd Msg
setTrack tr =
    Cmd.batch
        [ tr |> .relativePath |> Ports.setTrack
        , if isTrackAlreadyFetched tr then
            Cmd.none

          else
            Ports.getMetadata tr
        ]


isTrackAlreadyFetched : TrackInfo -> Bool
isTrackAlreadyFetched tr =
    tr.artist /= Nothing || tr.album /= Nothing || tr.title /= Nothing || tr.picture /= Nothing


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


getTheWorkingList : Player -> List ( Int, TrackInfo )
getTheWorkingList player =
    case player.shuffle of
        Enabled ls ->
            ls

        Disabled ->
            player.tracksList


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
        , Ports.enhancedTrack GotAnEnhancedTrack
        ]


getTrackInfoFromStatus : Player -> ( Int, TrackInfo )
getTrackInfoFromStatus player =
    player.status
        |> getCurrentTrack
        |> Maybe.andThen parsePath
        |> Maybe.withDefault ""
        |> Model.getTrackInfo player.tracksList


trackScrollId : String
trackScrollId =
    "track-"
