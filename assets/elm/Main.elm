module Main exposing (..)

import Html exposing (..)


type alias Model =
    Int


model : Model
model =
    0


update : msg -> Model -> Model
update msg model =
    case msg of
        _ ->
            model


view : Model -> Html msg
view model =
    h1 []
        [ text "Hello Elm program"
        ]


main : Program Never Model msg
main =
    Html.beginnerProgram
        { model = model
        , view = view
        , update = update
        }
