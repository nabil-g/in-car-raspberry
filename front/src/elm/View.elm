module View exposing (displayCurrentTrack, view, viewPlayerToolbar, viewTrack)

import Browser exposing (Document)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Html.Keyed as HK
import Model exposing (Model, PlayerStatus(..), Randomness(..), TrackInfo, getTrackInfo)
import Time
import Update exposing (Msg(..), getCurrentTrack, getTheFilteredList, parseCurrentTrack)


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
    in
    div []
        [ input [ type_ "text", placeholder "Rechercher", onInput Search ] []
        , HK.ul []
            (List.map (viewTrack model.status) <| getTheFilteredList model.search model.tracksList)
        , viewPlayerToolbar model
        , div []
            [ text <| String.fromInt <| Time.toHour zone ct
            , text ":"
            , text <| String.fromInt <| Time.toMinute zone ct
            ]
        ]


viewTrack : PlayerStatus -> ( Int, TrackInfo ) -> ( String, Html Msg )
viewTrack ps ( num, tr ) =
    let
        currentTrack =
            getCurrentTrack ps
                |> Maybe.andThen parseCurrentTrack
                |> Maybe.withDefault ""
                |> (==) tr.relativePath
    in
    ( String.fromInt num
    , li []
        [ a [ href "#", onClick <| SetTrack tr.relativePath ]
            [ text tr.filename
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

        ( shuffleMsg, shuffleTxt ) =
            if model.shuffle == Disabled then
                ( True, "Activer le mode aléatoire" )

            else
                ( False, "Désactiver le mode aléatoire" )
    in
    div []
        [ button [ onClick Previous, disabled disableOnError ] [ text "Prev" ]
        , button [ onClick buttonMsg, disabled disableOnError ] [ text buttonTxt ]
        , button [ onClick Next, disabled disableOnError ] [ text "Suiv" ]
        , button [ onClick <| ToggleLoop <| not model.loop, disabled disableOnError, style "margin-left" "10px" ]
            [ if model.loop then
                text "Désactiver la répétition"

              else
                text "Activer la répétition"
            ]
        , button [ onClick <| ToggleShuffle shuffleMsg, disabled disableOnError ]
            [ text shuffleTxt
            ]
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
