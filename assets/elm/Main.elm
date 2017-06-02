module Main exposing (main)

import Html exposing (Html, div, map, section)
import Html.Attributes exposing (class)
import Game
import Board
import Item


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { items : Item.Model }


type Msg
    = BoardMsg Board.Msg
    | ItemMsg Item.Msg
    | GameMsg Game.Msg


init : ( Model, Cmd Msg )
init =
    Model (Item.Model [] [] [])
        ! [ Game.getItems |> Cmd.map GameMsg
          ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        BoardMsg (Board.Index i j) ->
            model ! [ Cmd.none ]

        ItemMsg msg ->
            { model | items = Item.update msg model.items } ! [ Cmd.none ]

        GameMsg msg ->
            { model | items = Game.update msg model.items } ! [ Cmd.none ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


view : Model -> Html Msg
view model =
    div [ class "flex justify-center flex-wrap" ]
        [ Item.restItems model.items
        , section [ class "w-80-m w-40-l" ]
            [ Board.view BoardMsg
            , Item.myItems model.items ItemMsg
            ]
        ]
