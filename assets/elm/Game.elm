module Game exposing (..)

import Item
import Board
import Html exposing (Html, div, map, section, button, a, text)
import Json.Decode as JD
import Draggable
import Draggable.Events exposing (onDragBy, onDragStart)


type alias Model =
    { items : Item.Model
    , board : Board.Model
    , choices : List ( String, Int, Int )
    , myTurn : Bool
    , exchangeable : Bool
    , p1Stat : PlayerStat
    , p2Stat : PlayerStat
    , endStatus : EndStatus
    , xy : Position
    , drag : Draggable.State Position
    }


type alias Position =
    { x : Float, y : Float }


type alias PlayerStat =
    { deckName : String
    , point : Int
    , deckPoint : Maybe Int
    }


type Msg
    = SelectChoice Int Int String
    | OnDragBy Draggable.Delta
    | StartDragging Position
    | DragMsg (Draggable.Msg Position)


type EndStatus
    = DeckEnded
    | PassingEnded
    | Running


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
    , endStatus = Running
    , xy = Position -1 -1
    , drag = Draggable.init
    }


dragConfig : Draggable.Config Position Msg
dragConfig =
    Draggable.customConfig
        [ onDragBy OnDragBy
        , onDragStart StartDragging
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SelectChoice i j item ->
            ({ model | board = Board.markChoice i j item model.board },  Cmd.none )

        StartDragging initialPosition ->
            ({ model | xy = initialPosition },      Cmd.none )

        OnDragBy ( dx, dy ) ->
            ( { model | xy = Position (model.xy.x + dx) (model.xy.y + dy) }
            , Cmd.none
            )

        DragMsg dragMsg ->
            Draggable.update dragConfig dragMsg model


isDraging : Msg -> Bool
isDraging msg =
    case msg of
        OnDragBy _ ->
            True

        StartDragging _ ->
            True

        DragMsg _ ->
            True

        _ ->
            False


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
            let
                choicePos : String -> Position
                choicePos choiceType =
                    if model.xy == (Position -1 -1) then
                        if choiceType == "blank" then
                            { model | xy = Position -128 -69 }.xy
                        else
                            { model | xy = Position -75 -38 }.xy
                    else
                        model.xy
            in
                case item of
                    "blank" ->
                        Item.viewChoices (SelectChoice i j) DragMsg (choicePos item) (Item.itemChoices model.items)

                    "+/-" ->
                        Item.viewChoices (SelectChoice i j) DragMsg (choicePos item) [ "+", "-" ]

                    "x/÷" ->
                        Item.viewChoices (SelectChoice i j) DragMsg (choicePos item) [ "x", "÷" ]

                    _ ->
                        text ""

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
    , endStatus : EndStatus
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


endStatusDecoder : JD.Decoder EndStatus
endStatusDecoder =
    JD.string
        |> JD.andThen
            (\name ->
                case name of
                    "running" ->
                        JD.succeed Running

                    "passing_ended" ->
                        JD.succeed PassingEnded

                    "deck_ended" ->
                        JD.succeed DeckEnded

                    _ ->
                        JD.fail "Invalid end game status"
            )


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
        (JD.field "endStatus" endStatusDecoder)


joinedDecoder : JD.Decoder JoinedState
joinedDecoder =
    JD.map2 JoinedState
        myStateDecoder
        commonStateDecoder
