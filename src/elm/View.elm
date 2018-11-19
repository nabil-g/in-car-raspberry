module View exposing (displayCurrentTrack, view, viewPlayerToolbar, viewTrack)

import Browser exposing (Document)
import Browser.Dom as Dom
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Events exposing (onClick)
import Element.Font as Font
import Element.Input as Input
import Element.Keyed as EK
import Html as H
import Html.Attributes as HA
import Model exposing (Clock, Model, Player, PlayerStatus(..), Randomness(..), Route(..), TrackInfo, getTrackInfo, parsePath, routeToUrlString)
import Style exposing (..)
import Time exposing (Month(..), Weekday(..))
import Update exposing (Msg(..), getCurrentTrack, getTheFilteredList)
import Utils


view : Model -> Document Msg
view model =
    { title = "InCarRaspberry"
    , body = [ Element.layout [ Font.size 18, height fill, Background.color <| rgb255 112 135 240, Font.color whiteColor ] <| viewBody model ]
    }


viewBody : Model -> Element Msg
viewBody model =
    let
        currentPage =
            case model.routing.currentPage of
                Media ->
                    viewMedia model.player

                Settings ->
                    text "Réglages ..."

                NotFound ->
                    text "Pas trouvé ..."

                _ ->
                    text "Pas encore dispo ..."
    in
    row
        ([ width fill, height fill ]
            ++ artwork model.player.fullscreenArtwork
        )
        [ viewSideNavbar model
        , column [ width fill, height fill ]
            [ viewStatusBar model.clock
            , currentPage
            ]
        ]


artwork : Maybe String -> List (Attribute Msg)
artwork fsArtwork =
    case fsArtwork of
        Just pic ->
            [ inFront <| displayFullScreenArtwork CloseArtwork pic ]

        Nothing ->
            []


viewSideNavbar : Model -> Element Msg
viewSideNavbar model =
    let
        navLink route ico =
            link
                ([ padding 25, Font.size 25, centerX ]
                    ++ (if route == model.routing.currentPage then
                            []

                        else
                            [ Font.color <| rgba 255 255 255 0.4 ]
                       )
                )
                { url = routeToUrlString route, label = icon [] ico }
    in
    column [ height fill, Background.color <| rgba 0 0 0 0.2, padding 20 ]
        [ column [ width fill, centerY ]
            [ navLink Media "audio"
            , navLink Radio "radio"
            , navLink Navigation "navigation"
            , navLink RearCam "videocam"
            , navLink Settings "settings"
            ]
        ]


icon : List (H.Attribute msg) -> String -> Element msg
icon attrs name =
    html <| H.i [ HA.class ("zmdi zmdi-" ++ name) ] []


viewStatusBar : Clock -> Element Msg
viewStatusBar clock =
    let
        zone =
            clock.timezone

        ct =
            clock.currentTime
    in
    el [ width fill ] <|
        row [ alignRight, paddingXY 10 5 ]
            [ text <| Utils.dateToFrench zone ct
            , text " "
            , text <| Utils.formatSingleDigit <| Time.toHour zone ct
            , text ":"
            , text <| Utils.formatSingleDigit <| Time.toMinute zone ct
            ]


viewMedia : Player -> Element Msg
viewMedia player =
    column [ width fill, height fill, padding 5 ]
        [ viewSearchBar player
        , viewPlayerToolbar player
        , viewTracks player
        ]


viewSearchBar : Player -> Element Msg
viewSearchBar player =
    let
        lsLength =
            List.length player.tracksList

        placeholderTxt =
            if lsLength > 2 then
                " Rechercher parmi " ++ String.fromInt lsLength ++ " morceaux"

            else
                " Rechercher"
    in
    row [ spacing 10 ]
        [ Input.text [ Border.width 0, Background.color <| rgba 0 0 0 0, width <| px 300 ]
            { onChange = Search
            , text = player.search
            , placeholder = Just <| Input.placeholder [ Font.italic, Font.color whiteColor ] <| row [] [ icon [] "search", text placeholderTxt ]
            , label = Input.labelHidden "Rechercher"
            }
        , if player.search == "" then
            none

          else
            Input.button [] { onPress = Just ClearSearch, label = icon [] "close" }
        ]


viewTracks : Player -> Element Msg
viewTracks player =
    let
        filteredList =
            getTheFilteredList player.search player.tracksList

        list =
            if player.tracksList == [] then
                [ ( "", el [ centerX, centerY ] <| text "Rien de rien" ) ]

            else if filteredList == [] then
                [ ( "", el [ centerX, centerY ] <| text "Rien ne correspond à cette recherche" ) ]

            else
                List.map (viewTrack player.status) filteredList
    in
    EK.column [ clipY, scrollbarY, height <| maximum 500 fill, htmlAttribute <| HA.id "tracksList" ] list


viewTrack : PlayerStatus -> ( Int, TrackInfo ) -> ( String, Element Msg )
viewTrack ps ( num, tr ) =
    let
        currentTrack =
            getCurrentTrack ps
                |> Maybe.andThen parsePath
                |> Maybe.withDefault ""
                |> (==) tr.relativePath

        cutWords s =
            if String.length s > 55 then
                String.left 55 s ++ "..."

            else
                s
    in
    ( String.fromInt num
    , row
        ([ pointer
         , onClick <| SetTrack tr
         , padding 10
         , clipX
         ]
            ++ (if currentTrack then
                    [ Font.color greenColor ]

                else
                    []
               )
        )
        [ text <| cutWords tr.filename ]
    )


viewPlayerToolbar : Player -> Element Msg
viewPlayerToolbar player =
    let
        ( buttonMsg, buttonTxt ) =
            case player.status of
                Playing tr ->
                    ( Pause, "pause-circle-outline" )

                _ ->
                    ( Play, "play-circle-outline" )

        ( shuffleMsg, shuffleColor ) =
            if player.shuffle == Disabled then
                ( True, Font.color whiteColor )

            else
                ( False, Font.color greenColor )

        playerBtn ftsize msg label =
            Input.button [ Font.size ftsize, paddingXY 10 0, centerY ] { onPress = Just msg, label = label }
    in
    row [ width fill, height <| px 100, paddingXY 10 0, spacing 10 ]
        [ row [ spacing 5 ]
            [ playerBtn 30 Previous <| icon [] "skip-previous"
            , playerBtn 40 buttonMsg <| icon [] buttonTxt
            , playerBtn 30 Next <| icon [] "skip-next"
            , playerBtn 30
                (ToggleLoop <| not player.loop)
                (el
                    [ if player.loop then
                        Font.color greenColor

                      else
                        Font.color whiteColor
                    ]
                 <|
                    icon [] "repeat"
                )
            , playerBtn 30 (ToggleShuffle shuffleMsg) <| el [ shuffleColor ] <| icon [] "shuffle"
            ]
        , getTrackInfoFromStatus player
            |> displayCurrentTrack
        ]


displayCurrentTrack : TrackInfo -> Element Msg
displayCurrentTrack tri =
    let
        cutWords s =
            if String.length s > 35 then
                String.left 35 s ++ "..."

            else
                s
    in
    row [ width fill, spacing 5 ]
        [ column []
            [ el [ Font.bold ] <| text <| cutWords <| Maybe.withDefault tri.filename tri.title
            , text <| cutWords <| Maybe.withDefault "" tri.artist
            , el [ Font.italic ] <| text <| cutWords <| Maybe.withDefault "" tri.album
            ]
        , case tri.picture of
            Just pic ->
                el [ alignRight ] <| image [ height <| px 100, onClick <| DisplayArtwork pic ] { src = pic, description = "Pochette d'album" }

            Nothing ->
                none
        ]


displayFullScreenArtwork : msg -> String -> Element msg
displayFullScreenArtwork closeMsg pic =
    el
        [ width fill
        , height fill
        , behindContent <|
            el
                [ width fill
                , height fill
                , Background.color (rgba 0 0 0 0.7)
                , onClick closeMsg
                ]
                none
        , inFront <|
            el
                [ htmlAttribute <| HA.style "height" "100%"
                , htmlAttribute <| HA.style "width" "100%"
                , onClick closeMsg
                ]
            <|
                el
                    [ centerX, centerY ]
                <|
                    image [ width <| maximum 420 <| px 400 ] { src = pic, description = "Pochette d'album" }
        ]
    <|
        none


getTrackInfoFromStatus : Player -> TrackInfo
getTrackInfoFromStatus player =
    player.status
        |> getCurrentTrack
        |> Maybe.andThen parsePath
        |> Maybe.withDefault ""
        |> getTrackInfo player.tracksList
