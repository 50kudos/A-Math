module Item
    exposing
        ( Model
        , RestItem
        , DeckItem
        , Msg
        , init
        , update
        , recallItem
        , batchRecall
        , hideMovedItem
        , viewChoices
        , itemChoices
        , myItemsDecoder
        , restItemsDecoder
        , myItems
        , restItems
        )

import Html exposing (..)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import Json.Decode as JD
import List.Extra
import Helper as H


type alias Model =
    { deckId : String
    , deckName : String
    , myItems : List DeckItem
    , restItems : List RestItem
    }


type alias DeckItem =
    { item : String, point : Int, picked : Bool, moved : Bool }


type alias RestItem =
    { item : String, ea : Int }


type Msg
    = Pick Int
    | Put Int


init : Model
init =
    Model "" "" [] []


restItemsDecoder : JD.Decoder RestItem
restItemsDecoder =
    JD.map2 RestItem
        (JD.field "item" JD.string)
        (JD.field "ea" JD.int)


myItemsDecoder : JD.Decoder DeckItem
myItemsDecoder =
    JD.map4 DeckItem
        (JD.field "item" JD.string)
        (JD.field "point" JD.int)
        (JD.succeed False)
        (JD.succeed False)


update : Msg -> Model -> Model
update msg model =
    case msg of
        Pick int ->
            { model | myItems = updateDeck int model }

        Put int ->
            { model | myItems = updateDeck int model }


updateDeck : Int -> Model -> List DeckItem
updateDeck target model =
    let
        handlePick : Int -> DeckItem -> DeckItem
        handlePick i item =
            case ( i == target, item.picked ) of
                ( False, _ ) ->
                    item

                ( True, True ) ->
                    { item | picked = not item.picked }

                ( True, False ) ->
                    { item | picked = not item.moved }
    in
        case List.Extra.findIndices .picked model.myItems of
            [] ->
                model.myItems
                    |> List.indexedMap handlePick

            [ prevPicked ] ->
                model.myItems
                    |> List.Extra.swapAt prevPicked target
                    |> Maybe.withDefault model.myItems
                    |> List.map (\item -> { item | picked = False })

            _ ->
                model.myItems


hideMovedItem : Model -> Model
hideMovedItem model =
    let
        hideItem : DeckItem -> DeckItem
        hideItem item =
            if item.picked then
                { item | moved = True, picked = False }
            else
                item
    in
        { model | myItems = List.map hideItem model.myItems }


recallItem : Msg -> ( String, Int ) -> Model -> Result Model Model
recallItem msg ( itemId, point ) model =
    case msg of
        Put int ->
            Ok
                { model
                    | myItems =
                        model.myItems
                            |> List.Extra.updateAt int
                                (\item -> { item | item = itemId, point = point, moved = False })
                            |> Maybe.withDefault model.myItems
                }

        _ ->
            Err model


batchRecall : Model -> Model
batchRecall model =
    { model | myItems = List.map (\item -> { item | moved = False }) model.myItems }


myItems : Model -> (Msg -> msg) -> Html msg
myItems { myItems } toMsg =
    let
        tile : Int -> DeckItem -> Html Msg
        tile nth item =
            if item.moved then
                spacetile (Put nth)
            else
                div
                    [ class <|
                        "flex justify-center items-center mh1 w2 h2 pointer relative"
                            ++ H.colorByPick item
                    , onClick (Pick nth)
                    ]
                    [ span [] [ text (H.cast item.item) ]
                    , sub [ class "f8 fw5 moon-gray" ] [ text (toString item.point) ]
                    ]

        spacetile : Msg -> Html Msg
        spacetile msg =
            div [ class "bg-transparent ba mh1 w2 h2", onClick msg ] []
    in
        List.indexedMap tile myItems
            |> div [ class "flex justify-center items-center flex-auto" ]
            |> map toMsg


restItems : Model -> Html msg
restItems { restItems } =
    let
        tile : RestItem -> Html msg
        tile item =
            div [ class "ma1 flex justify-center items-center" ]
                [ div [ class "ba b--dark-blue blue w2 h2 flex justify-center items-center" ]
                    [ text (H.cast item.item) ]
                , span [ class "w1 tc silver pl1" ] [ text (toString item.ea) ]
                ]
    in
        section [ class "dn flex-ns flex-wrap items-end-l flex-column-l self-start-l mw5-l mb4 ph2 ph3-l w-100 vh-50-l" ]
            (List.map tile restItems)


itemChoices : Model -> List String
itemChoices { restItems } =
    restItems
        |> List.filter (\item -> not <| List.member item.item [ "blank", "+/-", "x/÷" ])
        |> List.map .item


viewChoices : (String -> msg) -> List String -> Html msg
viewChoices msg listA =
    let
        numPad : String -> Html msg
        numPad item =
            span
                [ class "flex items-center justify-center w2 h2 pa1 ba b--light-yellow light-yellow pointer f3 ma3"
                , onClick (msg item)
                ]
                [ text item ]
    in
        div
            [ class <|
                "flex justify-center justify-start-ns flex-wrap absolute mw6 "
                    ++ "f7 fw1 ba b--near-black bg-dark-gray2 z-999 o-90"
            , style [ ( "top", "50%" ), ( "left", "50%" ), ( "transform", "translateX(-50%) translateY(-50%)" ) ]
            ]
            (List.map numPad listA)
