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
    , exchangeable : Bool
    , p1Stat : PlayerStat
    , p2Stat : PlayerStat
    , ended : Bool
    }


type alias PlayerStat =
    { deckName : String
    , point : Int
    , deckPoint : Maybe Int
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
    , exchangeable = True
    , p1Stat = PlayerStat "" 0 Nothing
    , p2Stat = PlayerStat "" 0 Nothing
    , ended = False
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


type alias DeckState =
    { deckId : String
    , deckName : String
    , myItems : List Item.DeckItem
    }


type alias CommonState =
    { myTurn : Bool
    , exchangeable : Bool
    , boardItems : List Board.CommittedItem
    , restItems : List Item.RestItem
    , p1Stat : PlayerStat
    , p2Stat : PlayerStat
    , ended : Bool
    }


type alias JoinedState =
    { deck : DeckState
    , common : CommonState
    }


myStateDecoder : JD.Decoder DeckState
myStateDecoder =
    JD.map3 DeckState
        (JD.field "deckId" JD.string)
        (JD.field "deckName" deckNameDeocder)
        (JD.field "myItems" <| JD.list Item.myItemsDecoder)


deckNameDeocder : JD.Decoder String
deckNameDeocder =
    JD.string |> JD.andThen (\name -> JD.succeed <| "ID#" ++ name)


playerStatDecocder : JD.Decoder PlayerStat
playerStatDecocder =
    JD.map3 PlayerStat
        (JD.field "deckName" deckNameDeocder)
        (JD.field "point" JD.int)
        (JD.maybe <| JD.field "deckPoint" JD.int)


commonStateDecoder : JD.Decoder CommonState
commonStateDecoder =
    JD.map7 CommonState
        (JD.field "myTurn" JD.bool)
        (JD.field "exchangeable" JD.bool)
        (JD.field "boardItems" <| JD.list Board.committedItemsDecoder)
        (JD.field "restItems" <| JD.list Item.restItemsDecoder)
        (JD.field "p1Stat" playerStatDecocder)
        (JD.field "p2Stat" playerStatDecocder)
        (JD.field "gameEnded" JD.bool)


joinedDecoder : JD.Decoder JoinedState
joinedDecoder =
    JD.map2 JoinedState
        myStateDecoder
        commonStateDecoder
