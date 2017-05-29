module Main exposing (main)

import Html exposing (Html, div, map, section)
import Html.Attributes exposing (class)
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


init : ( Model, Cmd Msg )
init =
    Model (Item.Model [] [] []) ! [ Item.getItems |> Cmd.map ItemMsg ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        BoardMsg (Board.Index i j) ->
            model ! [ Cmd.none ]

        ItemMsg (Item.Fetch (Ok items)) ->
            { model | items = items } ! [ Cmd.none ]

        ItemMsg (Item.Fetch (Err _)) ->
            model ! [ Cmd.none ]

        ItemMsg (Item.Pick nth) ->
            model ! [ Cmd.none ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


view : Model -> Html Msg
view model =
    div [ class "flex justify-center flex-wrap" ]
        [ Item.restItems model.items
        , section [ class "w-80-m w-40-l" ]
            [ Board.view model.items |> map BoardMsg
            , Item.myItems model.items |> map ItemMsg
            ]
        ]
