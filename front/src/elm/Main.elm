module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Html.Keyed as HK
import Http exposing (decodeUri)
import Json.Decode as D
import Json.Decode.Pipeline as P exposing (decode, optional, required)
import Ports
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
    { tracksList : List ( Int, Track )
    , status : PlayerStatus
    , clock : Time
    , search : String
    }


type Randomness
    = Enabled (List ( Int, Track ))
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


type alias Track =
    String


type alias Base64 =
    String


initialModel : Model
initialModel =
    { tracksList = []
    , status = Empty
    , clock = 0
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
    | Search String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Search s ->
            let
                debug =
                    Debug.log "voici ma recherche" s
            in
            ( model, Cmd.none )

        SetTrack tr ->
            ( model, Ports.setTrack tr )

        Pause ->
            ( model, Ports.pause () )

        Previous ->
            case getCurrentTrack model.status of
                Just tr ->
                    let
                        ls =
                            getTheFilteredList model.search model.tracksList

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
                            getTheFilteredList model.search model.tracksList

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
                    getTheFilteredList model.search model.tracksList

                cmd =
                    case playerStatus of
                        Loaded tr ->
                            Ports.play ()

                        Ended tr ->
                            if ls /= [] then
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
                    case D.decodeString (D.list D.string) mess of
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


setAnotherTrack : List ( Int, Track ) -> Int -> String -> Cmd Msg
setAnotherTrack ls direction tr =
    if List.length ls > 1 then
        ls
            |> getAnotherTrack tr direction
            |> Debug.log "new track is : "
            |> Ports.setTrack
    else
        Cmd.none


getAnotherTrack : String -> Int -> List ( Int, Track ) -> String
getAnotherTrack tr direction ls =
    let
        parsedTr =
            Maybe.withDefault "" <| parseCurrentTrack tr

        curindex =
            List.filter (\( a1, a2 ) -> a2 == parsedTr) ls
                |> List.map (\( a1, a2 ) -> a1)
                |> List.head
                |> Maybe.withDefault 0

        nextTrackIndex =
            (curindex + direction) % List.length ls
    in
    ls
        |> List.filter (\tup -> Tuple.first tup == nextTrackIndex)
        |> List.map (\tup -> Tuple.second tup)
        |> List.head
        |> Maybe.withDefault ""


setTheFirstTrack : Model -> Cmd Msg
setTheFirstTrack model =
    if model.tracksList == [] then
        Cmd.none
    else
        model.tracksList
            |> List.head
            |> Maybe.withDefault ( 0, "" )
            |> Tuple.second
            |> Ports.setTrack


parseCurrentTrack : String -> Maybe String
parseCurrentTrack tr =
    tr
        |> String.dropLeft 22
        |> decodeUri


getTheFilteredList : String -> List ( Int, Track ) -> List ( Int, Track )
getTheFilteredList query ls =
    let
        filteringFunc el =
            String.contains query <| String.toLower el

        tracks =
            List.map (\element -> Tuple.second element) ls

        -- equivalent à foreach
        filteredList =
            List.filter filteringFunc tracks
    in
    List.indexedMap (\index el -> ( index, el )) filteredList



--getTheFilteredList : String -> List ( Int, Track ) -> List ( Int, Track )
--getTheFilteredList query ls =
--    let
--        filteringFunc el =
--            String.contains query <| String.toLower el
--    in
--    ls
--        |> List.map (\element -> Tuple.second element)
--        |> List.filter filteringFunc
--        |> List.indexedMap (,)
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
    let
        filteredList =
            getTheFilteredList model.search model.tracksList
    in
    div []
        [ input [ type_ "text", placeholder "Rechercher", onInput Search ] []
        , span []
            [ text <| format "%H" model.clock
            , text <| ":"
            , text <| format "%M" model.clock
            ]
        , HK.ul []
            (List.map (viewTrack model.status) filteredList)
        , viewPlayerToolbar model
        ]


viewTrack : PlayerStatus -> ( Int, Track ) -> ( String, Html Msg )
viewTrack ps ( num, tr ) =
    let
        currentTrack =
            getCurrentTrack ps
                |> Maybe.andThen parseCurrentTrack
                |> Maybe.withDefault ""
                |> (==) tr
    in
    ( toString num
    , li []
        [ a [ href "#", onClick <| SetTrack tr ]
            [ text tr
            , if currentTrack then
                text "  -  En écoute"
              else
                text ""
            ]
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
    in
    div []
        [ button [ onClick Previous, disabled disableOnError ] [ text "Prev" ]
        , button [ onClick buttonMsg, disabled disableOnError ] [ text buttonTxt ]
        , button [ onClick Next, disabled disableOnError ] [ text "Suiv" ]
        , status
        ]


displayCurrentTrack : Track -> Html Msg
displayCurrentTrack tri =
    div []
        [ p [] [ text tri ]
        ]


getTrackInfo : List ( Int, Track ) -> PlayingPath -> Track
getTrackInfo ls tr =
    ls
        |> List.map (\tup -> Tuple.second tup)
        |> List.filter (\el -> el == tr)
        |> List.head
        |> Maybe.withDefault ""
            ( { model | search = String.toLower s }, Cmd.none )
