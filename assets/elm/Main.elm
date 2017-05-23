module Main exposing (..)

import Html exposing (..)
import Board
import Item


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
        [ Item.digit
        , Item.tenDigit
        , Item.operators
        , Board.view |> map BoardMsg
        , Item.myItems
        ]
