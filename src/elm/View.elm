module View exposing (displayCurrentTrack, view, viewPlayerToolbar, viewTrack)

import Browser exposing (Document)
import Element exposing (Element, FocusStyle, Length, alignBottom, alignLeft, alignRight, alignTop, behindContent, centerX, centerY, clip, clipX, clipY, column, el, fill, fillPortion, focusStyle, height, html, htmlAttribute, image, inFront, layout, link, maximum, minimum, none, padding, paddingEach, paddingXY, paragraph, px, rgba, row, scrollbarY, shrink, spaceEvenly, spacing, spacingXY, text, width)
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
    , body = [ Element.layoutWith { options = [ focusStyle <| FocusStyle Nothing Nothing Nothing ] } [ Font.size 18, height <| px model.windowHeight ] <| viewBody model ]
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
                            [ Font.color whiteColor ]

                        else
                            []
                       )
                )
                { url = routeToUrlString route, label = icon [] ico }
    in
    row
        ([ width fill, height fill ]
            ++ (Maybe.withDefault [] <|
                    Maybe.map
                        (List.singleton
                            << inFront
                            << displayFullScreenArtwork CloseArtwork
                        )
                        model.player.fullscreenArtwork
               )
        )
        [ column [ height fill, width <| fillPortion 8, Background.color redColor ]
            [ navLink Media "audio"
            , navLink Settings "settings"
            ]
        , column [ height fill, width <| fillPortion 92 ]
            [ viewStatusBar model.clock
            , column [ width fill, height <| fillPortion 95 ]
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
    row [ width fill, Background.color greenColor, height <| fillPortion 5 ]
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
    EK.column [ scrollbarY, clipX, height <| px 300, width <| px 729, Border.color blackColor, Border.width 1 ] list


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
    , row
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
    row [ width fill, Background.color blueColor, height <| px 100 ]
        [ Input.button [ htmlAttribute <| HA.disabled disableOnError, Font.size 30, paddingXY 10 0 ] { onPress = Just Previous, label = icon [] "skip-previous" }
        , Input.button [ htmlAttribute <| HA.disabled disableOnError, Font.size 35, paddingXY 10 0 ] { onPress = Just buttonMsg, label = icon [] buttonTxt }
        , Input.button [ htmlAttribute <| HA.disabled disableOnError, Font.size 30, paddingXY 10 0 ] { onPress = Just Next, label = icon [] "skip-next" }
        , Input.button [ htmlAttribute <| HA.disabled disableOnError, Font.size 30, paddingXY 10 0 ]
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

        --        , text <| String.fromInt <| List.length player.tracksList
        --        , x
        , status
        ]


displayCurrentTrack : TrackInfo -> Element Msg
displayCurrentTrack tri =
    row [ width fill, spaceEvenly ]
        [ column [ width <| fillPortion 5, clip ]
            [ row [ Font.bold ] [ text <| Maybe.withDefault tri.filename tri.title ]
            , row [] [ text <| Maybe.withDefault "" tri.artist ]
            , row [ Font.italic ] [ text <| Maybe.withDefault "" tri.album ]
            ]
        , row
            [ width <| fillPortion 5 ]
            [ case tri.picture of
                Just pic ->
                    image [ height <| px 100, onClick <| DisplayArtwork pic ] { src = pic, description = "Pochette d'album" }

                Nothing ->
                    none
            ]
        ]


x =
    row [ width fill, spaceEvenly, clip ]
        [ column [ width <| fillPortion 5, clip ]
            --            [ row [ Font.bold ] [ text <| Maybe.withDefault tri.filename tri.title ]
            [ row [ Font.bold, clip ] [ text "in Your Arms EP - Benjamin Diamond - In Your ArmsWe Gonna Make It (Alan Braxe mix).mp3" ]
            , row [] [ text <| "xxxxxxxxxxxxxxxxxxxxxxx" ]
            , row [ Font.italic, clip ] [ text <| "xxxxxxxxxxxxxxxxxxxxxxx" ]
            ]
        , row
            [ width <| fillPortion 5 ]
            --            [ case tri.picture of
            --                Just pic ->
            [ image [ width <| px 100, onClick <| DisplayArtwork "68ff971e983a0298100564f03702e46f.jpg" ] { src = "68ff971e983a0298100564f03702e46f.jpg", description = "Pochette d'album" }

            --                Nothing ->
            --                    none
            ]
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
                , htmlAttribute <| HA.style "pointer-events" "none"
                , htmlAttribute <| HA.style "position" "fixed"
                ]
            <|
                el
                    [ centerX
                    , centerY
                    , htmlAttribute <| HA.style "pointer-events" "all"
                    , htmlAttribute <| HA.style "max-height" "90%"
                    , htmlAttribute <| HA.style "width" "min-content"
                    , scrollbarY
                    ]
                <|
                    image [ width <| maximum 500 <| px 300 ] { src = pic, description = "Pochette d'album" }
        ]
    <|
        none
