module View exposing (displayCurrentTrack, view, viewPlayerToolbar, viewTrack)

import Browser exposing (Document)
import Browser.Dom as Dom
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
import Time exposing (Month(..), Weekday(..))
import Update exposing (Msg(..), getCurrentTrack, getTheFilteredList)
import Utils


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
                    text "Pas trouvé ..."

                _ ->
                    text "Pas encore dispo ..."

        navLink route ico =
            link
                ([ padding 25, Font.size 25, centerX ]
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
            [ column [ width fill, centerY ]
                [ navLink Media "audio"
                , navLink Radio "radio"
                , navLink Navigation "navigation"
                , navLink RearCam "videocam"
                , navLink Settings "settings"
                ]
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
    in
    row [ width fill, Background.color greenColor, height <| fillPortion 5 ]
        [ row [ alignRight ]
            [ text <| Utils.dateToFrench zone ct
            , text " "
            , text <| Utils.formatSingleDigit <| Time.toHour zone ct
            , text ":"
            , text <| Utils.formatSingleDigit <| Time.toMinute zone ct
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
    let
        lsLength =
            List.length player.tracksList

        placeholderTxt =
            if lsLength > 2 then
                " Rechercher parmi " ++ String.fromInt lsLength ++ " morceaux"

            else
                " Rechercher"
    in
    row []
        [ Input.text [ Border.width 0 ]
            { onChange = Search
            , text = player.search
            , placeholder = Just <| Input.placeholder [ Font.italic ] <| row [] [ icon [] "search", text placeholderTxt ]
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
    EK.column [ scrollbarY, clipX, height <| px 300, width <| px 729, htmlAttribute <| HA.id "tracksList" ] list


viewTrack : PlayerStatus -> ( Int, TrackInfo ) -> ( String, Element Msg )
viewTrack ps ( num, tr ) =
    let
        currentTrack =
            getCurrentTrack ps
                |> Maybe.andThen parsePath
                |> Maybe.withDefault ""
                |> (==) tr.relativePath

        bkgndColor =
            if modBy 2 num == 0 then
                "#f7f7f7"

            else
                "#ffffff"
    in
    ( String.fromInt num
    , row
        ([ htmlAttribute <| HA.style "cursor" "pointer"
         , onClick <| SetTrack tr
         , htmlAttribute <| HA.id <| (++) "track-" <| String.fromInt num
         , padding 10
         , width fill
         , clipX
         , htmlAttribute <| HA.style "background-color" bkgndColor
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

        playerBtn ftsize msg label =
            Input.button [ htmlAttribute <| HA.disabled disableOnError, Font.size ftsize, paddingXY 10 0, centerY ] { onPress = Just msg, label = label }
    in
    row [ width fill, Background.color blueColor, height <| px 100, paddingXY 10 0, spacing 10 ]
        [ row [ spacing 5 ]
            [ playerBtn 30 Previous <| icon [] "skip-previous"
            , playerBtn 40 buttonMsg <| icon [] buttonTxt
            , playerBtn 30 Next <| icon [] "skip-next"
            , playerBtn 30
                (ToggleLoop <| not player.loop)
                (el
                    [ if player.loop then
                        Font.color redColor

                      else
                        Font.color blackColor
                    ]
                 <|
                    icon [] "repeat"
                )
            , playerBtn 30 (ToggleShuffle shuffleMsg) <| el [ shuffleColor ] <| icon [] "shuffle"
            ]
        , status
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
            [ row [ Font.bold ] [ text <| cutWords <| Maybe.withDefault tri.filename tri.title ]
            , row [] [ text <| cutWords <| Maybe.withDefault "" tri.artist ]
            , row [ Font.italic ] [ text <| cutWords <| Maybe.withDefault "" tri.album ]
            ]
        , row
            [ alignRight ]
            [ case tri.picture of
                Just pic ->
                    image [ height <| px 100, onClick <| DisplayArtwork pic ] { src = pic, description = "Pochette d'album" }

                Nothing ->
                    none
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
                , onClick closeMsg
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
                    image [ width <| maximum 420 <| px 400 ] { src = pic, description = "Pochette d'album" }
        ]
    <|
        none
