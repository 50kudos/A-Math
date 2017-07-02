module Game exposing (..)

import Item
import Board
import Html exposing (Html, div, map, section, button, a, text)
import Json.Decode as JD


type alias Model =
    { items : Item.Model
    , board : Board.Model
    , choices : List ( String, Int, Int )
    , myTurn : Bool
    , p1Point : Int
    , p2Point : Int
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
    { items = Item.init
    , board = Board.init
    , choices = []
    , myTurn = False
    , p1Point = 0
    , p2Point = 0
    }


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


type alias CommonState =
    { board : Board.Model
    , myTurn : Bool
    , p1Point : Int
    , p2Point : Int
    }


decoder : JD.Decoder Model
decoder =
    JD.map6 Model
        (Item.decoder)
        (Board.decoder)
        (JD.succeed [])
        (JD.field "myTurn" JD.bool)
        (JD.field "p1Point" JD.int)
        (JD.field "p2Point" JD.int)


commonStateDecoder : JD.Decoder CommonState
commonStateDecoder =
    JD.map4 CommonState
        (Board.decoder)
        (JD.field "myTurn" JD.bool)
        (JD.field "p1Point" JD.int)
        (JD.field "p2Point" JD.int)
