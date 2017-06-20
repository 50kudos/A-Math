module Game exposing (..)

import Item
import Board
import Html exposing (Html, div, map, section, button, a, text)
import Json.Decode as JD


type alias Model =
    { items : Item.Model
    , board : Board.Model
    , choices : List ( String, Int, Int )
    }


type Msg
    = SelectChoice Int Int String


type Choice
    = PlusMinus
    | MultiplyDivive
    | Blank


type Source
    = FromBoard ( String, Int )
    | FromDeck ( String, Int )


type Destination
    = ToBoard
    | ToDeck


init : Model
init =
    Model Item.init Board.init []


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SelectChoice i j item ->
            { model | board = Board.markChoice i j item model.board } ! [ Cmd.none ]


updateItems : Item.Msg -> Model -> Model
updateItems msg model =
    case toMove ToDeck model of
        FromBoard item ->
            case Item.recallItem msg item model.items of
                Ok items ->
                    { model
                        | items = items
                        , board = Board.hideMovedItem model.board
                    }

                Err _ ->
                    model

        FromDeck _ ->
            { model | items = Item.update msg model.items }


updateBoard : Board.Msg -> Model -> Model
updateBoard msg model =
    case toMove ToBoard model of
        FromDeck item ->
            case Board.addItem msg item model.board of
                Ok board ->
                    { model
                        | board = board
                        , items =
                            Item.hideMovedItem model.items
                    }

                Err _ ->
                    model

        FromBoard _ ->
            { model | board = Board.update msg model.board }


toMove : Destination -> Model -> Source
toMove move_ { items, board } =
    case move_ of
        ToBoard ->
            case List.filter .picked items.myItems of
                [ pickedItem ] ->
                    FromDeck ( pickedItem.item, pickedItem.point )

                _ ->
                    FromBoard ( "", 0 )

        ToDeck ->
            case List.filter .picked board.stagingItems of
                [ pickedItem ] ->
                    FromBoard ( pickedItem.item, pickedItem.point )

                _ ->
                    FromDeck ( "", 0 )


viewChoiceFor : Maybe ( String, Int, Int ) -> Model -> Html Msg
viewChoiceFor position model =
    case position of
        Just ( item, i, j ) ->
            case item of
                "blank" ->
                    Item.viewChoices (SelectChoice i j) (Item.itemChoices model.items)

                "+/-" ->
                    Item.viewChoices (SelectChoice i j) [ "+", "-" ]

                "x/÷" ->
                    Item.viewChoices (SelectChoice i j) [ "x", "÷" ]

                _ ->
                    Debug.crash "Unexpected selectable item occurs."

        Nothing ->
            text ""


type alias CommonState a =
    { restItems : List a
    , board : Board.Model
    }


decoder : JD.Decoder Model
decoder =
    JD.map3 Model
        (Item.decoder)
        (Board.decoder)
        (JD.succeed [])


commonStateDecoder : JD.Decoder (CommonState Item.RestItem)
commonStateDecoder =
    JD.map2 CommonState
        (JD.field "restItems" <| JD.list Item.restItemsDecoder)
        (Board.decoder)
