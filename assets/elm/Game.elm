module Game exposing (..)

import Item
import Board
import Html exposing (Html, div, map, section)
import Html.Attributes exposing (class)
import Http
import Json.Decode as JD


type alias Model =
    { items : Item.Model
    }


type Msg
    = Fetch (Result Http.Error Model)
    | ItemMsg Item.Msg
    | BoardMsg Board.Msg


init : Model
init =
    { items = Item.init }


decoder : JD.Decoder Model
decoder =
    JD.map Model Item.decoder


update : Msg -> Model -> Model
update msg model =
    case msg of
        ItemMsg msg ->
            { model | items = Item.update msg model.items }

        BoardMsg (Board.Index i j) ->
            model

        Fetch (Ok gameData) ->
            { model | items = gameData.items }

        Fetch (Err error) ->
            Debug.log (toString error) model


getItems : Cmd Msg
getItems =
    Http.send Fetch <|
        Http.get "http://localhost:4000/api/items/3" decoder


view : Model -> Html Msg
view model =
    div [ class "flex justify-center flex-wrap" ]
        [ Item.restItems model.items
        , section [ class "w-80-m w-40-l" ]
            [ Board.view BoardMsg
            , Item.myItems model.items ItemMsg
            ]
        ]
