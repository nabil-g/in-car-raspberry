module View exposing (displayCurrentTrack, view, viewPlayerToolbar, viewTrack)

import Browser exposing (Document)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Html.Keyed as HK
import Model exposing (Model, Player, PlayerStatus(..), Randomness(..), Route(..), TrackInfo, getTrackInfo, parsePath)
import Time
import Update exposing (Msg(..), getCurrentTrack, getTheFilteredList)


view : Model -> Document Msg
view model =
    { title = "InCarRaspberry"
    , body = [ viewBody model ]
    }


viewBody : Model -> Html Msg
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
    div []
        [ div []
            [ a [ href "/media", style "margin-right" "10px" ] [ text "Audio" ]
            , a [ href "/settings" ] [ text "Réglages" ]
            ]
        , div []
            [ text <| format <| Time.toHour zone ct
            , text ":"
            , text <| format <| Time.toMinute zone ct
            ]
        , currentPage
        ]


viewMedia : Player -> Html Msg
viewMedia player =
    div []
        [ input [ type_ "text", placeholder "Rechercher", onInput Search, value player.search ] []
        , button [ onClick ClearSearch ] [ text "Effacer" ]
        , viewPlayerToolbar player
        , HK.ul []
            (List.map (viewTrack player.status) <| getTheFilteredList player.search player.tracksList)
        ]


viewTrack : PlayerStatus -> ( Int, TrackInfo ) -> ( String, Html Msg )
viewTrack ps ( num, tr ) =
    let
        currentTrack =
            getCurrentTrack ps
                |> Maybe.andThen parsePath
                |> Maybe.withDefault ""
                |> (==) tr.relativePath
    in
    ( String.fromInt num
    , li
        [ style "cursor" "pointer"
        , onClick <| SetTrack tr
        , if currentTrack then
            style "color" "green"

          else
            class ""
        ]
        [ text tr.filename ]
    )


viewPlayerToolbar : Player -> Html Msg
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
                    text ""

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
    div []
        [ button [ onClick Previous, disabled disableOnError ] [ text "Prev" ]
        , button [ onClick buttonMsg, disabled disableOnError ] [ text buttonTxt ]
        , button [ onClick Next, disabled disableOnError ] [ text "Suiv" ]
        , button [ onClick <| ToggleLoop <| not player.loop, disabled disableOnError, style "margin-left" "10px" ]
            [ if player.loop then
                text "Désactiver la répétition"

              else
                text "Activer la répétition"
            ]
        , button [ onClick <| ToggleShuffle shuffleMsg, disabled disableOnError ]
            [ text shuffleTxt
            ]
        , text <| String.fromInt <| List.length player.tracksList
        , status
        ]


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
