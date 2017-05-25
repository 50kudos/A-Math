module Main exposing (main)

import Html exposing (Html, div, map)
import Html.Attributes exposing (class)
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
    div [ class "flex justify-center items-center min-vh-100 bg-dark-gray2" ]
        [ Item.digit
        , Board.view |> map BoardMsg
        ]
