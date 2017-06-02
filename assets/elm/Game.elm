module Game exposing (..)

import Item
import Board
import Html exposing (Html, div, map, section)
import Html.Attributes exposing (class)
import Http
import Json.Decode as JD
import List.Extra


type alias Model =
    { items : Item.Model
    , board : Board.Model
    }


type Msg
    = Fetch (Result Http.Error Model)
    | ItemMsg Item.Msg
    | BoardMsg Board.Msg


init : Model
init =
    Model Item.init Board.init


update : Msg -> Model -> Model
update msg model =
    case msg of
        ItemMsg msg ->
            { model | items = Item.update msg model.items }

        BoardMsg msg ->
            { model | board = Board.update msg model.board }

        Fetch (Ok gameData) ->
            { model | items = gameData.items, board = gameData.board }

        Fetch (Err error) ->
            Debug.log (toString error) model


view : Model -> Html Msg
view model =
    div [ class "flex justify-center flex-wrap" ]
        [ Item.restItems model.items
        , section [ class "w-80-m w-40-l" ]
            [ Board.view model.board BoardMsg
            , Item.myItems model.items ItemMsg
            ]
        ]


decoder : JD.Decoder Model
decoder =
    JD.map2 Model
        (Item.decoder)
        (Board.decoder)


getItems : Cmd Msg
getItems =
    Http.send Fetch <|
        Http.get "http://localhost:4000/api/items/3" decoder
