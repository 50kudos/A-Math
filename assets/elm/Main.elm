module Main exposing (..)

import Html exposing (..)
import Board


main : Program Never Model Msg
main =
    Html.beginnerProgram
        { model = model
        , view = view
        , update = update
        }


type alias Model =
    ( Int, Int )


type Msg
    = BoardMsg Board.Msg


model : Model
model =
    ( 0, 0 )


update : Msg -> Model -> Model
update msg model =
    case msg of
        BoardMsg (Board.Index ( i, j )) ->
            ( i, j )


view : Model -> Html Msg
view model =
    div []
        [ Board.view |> map BoardMsg
        ]
