module Main exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing ( onClick )


-- APP
main : Program Never Model Msg
main =
  Html.beginnerProgram { model = model, view = view, update = update }


-- MODEL
type alias Model = Int

model : Model
model = 0


-- UPDATE
type Msg = NoOp

update : Msg -> Model -> Model
update msg model =
  case msg of
    NoOp -> model


-- VIEW

view : Model -> Html Msg
view model =
  div [  ][

  ]
