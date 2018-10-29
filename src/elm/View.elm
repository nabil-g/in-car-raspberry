module View exposing (displayCurrentTrack, view, viewPlayerToolbar, viewTrack)

import Browser exposing (Document)
import Element exposing (Element, Length, alignBottom, alignLeft, alignRight, alignTop, centerX, centerY, column, el, fill, fillPortion, height, html, htmlAttribute, image, layout, link, maximum, minimum, none, padding, paddingEach, paddingXY, paragraph, px, row, scrollbarY, shrink, spaceEvenly, spacing, spacingXY, text, width)
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
import Time exposing (Month(..))
import Update exposing (Msg(..), getCurrentTrack, getTheFilteredList)


view : Model -> Document Msg
view model =
    { title = "InCarRaspberry"
    , body = [ Element.layout [ Font.size 18 ] <| viewBody model ]
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
                    text "Not found"

        navLink route ico =
            link
                ([ padding 25, Font.size 25 ]
                    ++ (if route == model.routing.currentPage then
                            [ Border.widthEach { bottom = 3, left = 0, right = 0, top = 0 }, Border.color blackColor ]

                        else
                            []
                       )
                )
                { url = routeToUrlString route, label = icon [] ico }
    in
    row [ width fill, height fill ]
        [ column [ height fill, width <| fillPortion 8, Background.color redColor ]
            [ navLink Media "audio"
            , navLink Settings "settings"
            ]
        , column [ height fill, width <| fillPortion 92 ]
            [ viewStatusBar model.clock
            , column [ width fill, height <| fillPortion 9 ]
                [ currentPage
                ]
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

        format num =
            if num >= 0 && num < 10 then
                "0" ++ String.fromInt num

            else
                String.fromInt num

        monthToInt num =
            case num of
                Jan ->
                    1

                Feb ->
                    2

                Mar ->
                    3

                Apr ->
                    4

                May ->
                    5

                Jun ->
                    6

                Jul ->
                    7

                Aug ->
                    8

                Sep ->
                    9

                Oct ->
                    10

                Nov ->
                    11

                _ ->
                    12
    in
    row [ width fill, Background.color greenColor, height <| fillPortion 1 ]
        [ row [ alignRight ]
            [ text <| String.join "-" <| List.map format [ Time.toDay zone ct, monthToInt <| Time.toMonth zone ct, Time.toYear zone ct ]
            , text " "
            , text <| format <| Time.toHour zone ct
            , text ":"
            , text <| format <| Time.toMinute zone ct
            ]
        ]


viewMedia : Player -> Element Msg
viewMedia player =
    column [ width fill, height fill ]
        [ viewSearchBar player
        , viewTracks player
        , viewPlayerToolbar player
        ]


viewSearchBar : Player -> Element Msg
viewSearchBar player =
    row []
        [ Input.text []
            { onChange = Search
            , text = player.search
            , placeholder = Just <| Input.placeholder [] <| row [] [ icon [] "search", text " Rechercher" ]
            , label = Input.labelHidden "Rechercher"
            }
        , Input.button [] { onPress = Just ClearSearch, label = icon [] "close" }
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
    EK.column [ scrollbarY, height <| px 300, Border.color blackColor, Border.width 1, htmlAttribute <| HA.style "text-overflow" "ellipsis" ] list


viewTrack : PlayerStatus -> ( Int, TrackInfo ) -> ( String, Element Msg )
viewTrack ps ( num, tr ) =
    let
        currentTrack =
            getCurrentTrack ps
                |> Maybe.andThen parsePath
                |> Maybe.withDefault ""
                |> (==) tr.relativePath
    in
    ( String.fromInt num
    , paragraph
        ([ htmlAttribute <| HA.style "cursor" "pointer"
         , onClick <| SetTrack tr
         ]
            ++ (if currentTrack then
                    [ htmlAttribute <| HA.style "color" "green" ]

                else
                    []
               )
        )
        [ text tr.filename ]
    )


viewPlayerToolbar : Player -> Element Msg
viewPlayerToolbar player =
    let
        status =
            case getCurrentTrack player.status of
                Just tr ->
                    tr
                        |> parsePath
                        |> Maybe.withDefault ""
                        |> getTrackInfo player.tracksList
                        |> displayCurrentTrack

                Nothing ->
                    none

        ( buttonMsg, buttonTxt ) =
            case player.status of
                Playing tr ->
                    ( Pause, "pause-circle-outline" )

                _ ->
                    ( Play, "play-circle-outline" )

        disableOnError =
            case player.status of
                Error _ ->
                    True

                _ ->
                    False

        ( shuffleMsg, shuffleColor ) =
            if player.shuffle == Disabled then
                ( True, Font.color blackColor )

            else
                ( False, Font.color redColor )
    in
    row [ width fill, height fill ]
        [ Input.button [ htmlAttribute <| HA.disabled disableOnError, Font.size 30, padding 20 ] { onPress = Just Previous, label = icon [] "skip-previous" }
        , Input.button [ htmlAttribute <| HA.disabled disableOnError, Font.size 35, padding 20 ] { onPress = Just buttonMsg, label = icon [] buttonTxt }
        , Input.button [ htmlAttribute <| HA.disabled disableOnError, Font.size 30, padding 20 ] { onPress = Just Next, label = icon [] "skip-next" }
        , Input.button [ htmlAttribute <| HA.disabled disableOnError, Font.size 30, padding 20 ]
            { onPress = Just <| ToggleLoop <| not player.loop
            , label =
                el
                    [ if player.loop then
                        Font.color redColor

                      else
                        Font.color blackColor
                    ]
                <|
                    icon [] "repeat"
            }
        , Input.button [ htmlAttribute <| HA.disabled disableOnError, Font.size 30, padding 20 ] { onPress = Just <| ToggleShuffle shuffleMsg, label = el [ shuffleColor ] <| icon [] "shuffle" }
        , text <| String.fromInt <| List.length player.tracksList
        , status
        ]


displayCurrentTrack : TrackInfo -> Element Msg
displayCurrentTrack tri =
    row [ width fill ]
        [ paragraph []
            [ el [] <| text <| Maybe.withDefault tri.filename tri.title
            , el [] <| text <| Maybe.withDefault "" tri.artist
            , el [] <| text <| Maybe.withDefault "" tri.album
            , case tri.picture of
                Just pic ->
                    image [ width <| px 100 ] { src = pic, description = "Pochette d'album" }

                Nothing ->
                    none
            ]
        ]
