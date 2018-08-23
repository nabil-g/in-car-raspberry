module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import WebSocket
import Json.Decode as D
import Json.Decode.Pipeline exposing (decode, required)


-- APP


main : Program Never Model Msg
main =
    Html.program { init = ( initialModel, Cmd.none ), view = view, update = update, subscriptions = subscriptions }



-- MODEL


type alias Model =
    Int

type alias TrackInfo = {
    filename: String
    , title: Maybe String
    , artist: Maybe String
    , album: Maybe String
}

initialModel : Model
initialModel =
    0



socketPath : String
socketPath =
    "ws://localhost:8082"



-- UPDATE


type Msg
    = NoOp
    | NewMessage String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        NewMessage mess ->
            let
                x =
                    Debug.log "reçu ---> " mess
            in
                ( model, WebSocket.send socketPath "bien reçu!" )





-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions m =
    --    Sub.none
    WebSocket.listen socketPath NewMessage



-- VIEW


view : Model -> Html Msg
view model =
    div []
        []
