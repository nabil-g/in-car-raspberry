module View exposing (displayCurrentTrack, view, viewPlayerToolbar, viewTrack)

import Browser exposing (Document)
import Element exposing (Element, column, el, html, htmlAttribute, image, layout, link, none, paragraph, row, text)
import Element.Background as Background
import Element.Border as Border
import Element.Events exposing (onClick)
import Element.Input as Input
import Element.Keyed as EK
import Html as H
import Html.Attributes as HA
import Model exposing (Model, Player, PlayerStatus(..), Randomness(..), Route(..), TrackInfo, getTrackInfo, parsePath)
import Time
import Update exposing (Msg(..), getCurrentTrack, getTheFilteredList)


view : Model -> Document Msg
view model =
    { title = "InCarRaspberry"
    , body = [ Element.layout [] <| viewBody model ]
    }


viewBody : Model -> Element Msg
viewBody model =
    let
        zone =
            model.clock.timezone

        ct =
            model.clock.currentTime

        currentPage =
            case model.routing.currentPage of
                Media ->
                    viewMedia model.player

                Settings ->
                    text "Réglages ..."

                NotFound ->
                    text "Not found"

        format num =
            if num >= 0 && num < 10 then
                "0" ++ String.fromInt num

            else
                String.fromInt num
    in
    row []
        [ column []
            [ link [] { url = "/media", label = text "Audio" }
            , link [] { url = "/settings", label = text "Réglages" }
            ]
        , column []
            [ paragraph []
                [ text <| format <| Time.toHour zone ct
                , text ":"
                , text <| format <| Time.toMinute zone ct
                ]
            , currentPage
            ]
        ]


viewMedia : Player -> Element Msg
viewMedia player =
    column []
        [ Input.text []
            { onChange = Search
            , text = player.search
            , placeholder = Just <| Input.placeholder [] <| text "Rechercher"
            , label = Input.labelHidden "Rechercher"
            }
        , Input.button [] { onPress = Just ClearSearch, label = text "Effacer" }
        , viewPlayerToolbar player
        , EK.column []
            (List.map (viewTrack player.status) <| getTheFilteredList player.search player.tracksList)
        ]


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
                    ( Pause, "Pause" )

                _ ->
                    ( Play, "Lire" )

        disableOnError =
            case player.status of
                Error _ ->
                    True

                _ ->
                    False

        ( shuffleMsg, shuffleTxt ) =
            if player.shuffle == Disabled then
                ( True, "Activer le mode aléatoire" )

            else
                ( False, "Désactiver le mode aléatoire" )
    in
    row []
        [ Input.button [ htmlAttribute <| HA.disabled disableOnError ] { onPress = Just Previous, label = text "Prev" }
        , Input.button [ htmlAttribute <| HA.disabled disableOnError ] { onPress = Just buttonMsg, label = text buttonTxt }
        , Input.button [ htmlAttribute <| HA.disabled disableOnError ] { onPress = Just Next, label = text "Suiv" }
        , Input.button [ htmlAttribute <| HA.disabled disableOnError ]
            { onPress = Just <| ToggleLoop <| not player.loop
            , label =
                if player.loop then
                    text "Désactiver la répétition"

                else
                    text "Activer la répétition"
            }
        , Input.button [ htmlAttribute <| HA.disabled disableOnError ] { onPress = Just <| ToggleShuffle shuffleMsg, label = text shuffleTxt }
        , text <| String.fromInt <| List.length player.tracksList
        , status
        ]


displayCurrentTrack : TrackInfo -> Element Msg
displayCurrentTrack tri =
    column []
        [ paragraph [] [ text <| Maybe.withDefault tri.filename tri.title ]
        , paragraph [] [ text <| Maybe.withDefault "" tri.artist ]
        , paragraph [] [ text <| Maybe.withDefault "" tri.album ]
        , case tri.picture of
            Just pic ->
                image [] { src = pic, description = "Pochette d'album" }

            Nothing ->
                none
        ]
