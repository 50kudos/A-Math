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
import Draggable


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
    { deckId = ""
    , deckName = ""
    , myItems = List.repeat 8 <| DeckItem "" 0 False False
    , restItems = List.repeat 29 <| RestItem "" 0
    }


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
recallItem msg ( itemStr, point ) model =
    case msg of
        Put targetIndex ->
            let
                selfIndex =
                    List.Extra.findIndex (\item -> item.item == itemStr && item.moved) model.myItems
                        |> Maybe.withDefault targetIndex
            in
                Ok
                    { model
                        | myItems =
                            model.myItems
                                |> List.Extra.swapAt selfIndex targetIndex
                                |> Maybe.withDefault model.myItems
                                |> List.Extra.updateAt targetIndex
                                    (\item -> { item | item = itemStr, point = point, moved = False })
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
                    [ span [] [ H.cast item.item ]
                    , sub [ class "f8 fw5 moon-gray" ] [ text (toString item.point) ]
                    ]

        spacetile : Msg -> Html Msg
        spacetile msg =
            div [ class "bg-transparent ba mh1 w2 h2", onClick msg ] []
    in
        List.indexedMap tile myItems
            |> div [ class "flex justify-center items-center flex-auto h2" ]
            |> map toMsg


restItems : Model -> Html msg
restItems { restItems } =
    let
        tile : RestItem -> Html msg
        tile item =
            div [ class "ma1 flex justify-center items-center" ]
                [ div [ class "ba b--dark-blue blue w2 h2 flex justify-center items-center" ]
                    [ H.cast item.item ]
                , span [ class "w1 tc silver pl1" ] [ text (toString item.ea) ]
                ]
    in
        section [ class "dn flex-ns flex-wrap items-end-l flex-column-l self-start-l mw5-l ma2 ma0-l ph2 ph3-l w-100 vh-50-l" ]
            (List.map tile restItems)


itemChoices : Model -> List String
itemChoices { restItems } =
    restItems
        |> List.filter (\item -> not <| List.member item.item [ "blank", "+/-", "x/÷" ])
        |> List.map .item


viewChoices : (String -> msg) -> (Draggable.Msg { x : Float, y : Float } -> msg) -> { x : Float, y : Float } -> List String -> Html msg
viewChoices msg dragMsg position listA =
    let
        shortChoices : String -> Html msg
        shortChoices item =
            span
                [ class "flex items-center justify-center w2 h2 pa1 ba b--light-yellow light-yellow pointer f3 ma3"
                , onClick (msg item)
                ]
                [ text item ]

        longChoices : String -> Html msg
        longChoices item =
            span
                [ class "flex items-center justify-center w1 h1 pa2 ba b--light-yellow light-yellow pointer f4 ma0"
                , onClick (msg item)
                ]
                [ text item ]

        translate : String
        translate =
            "translate(" ++ (toString position.x) ++ "px, " ++ (toString position.y) ++ "px)"
    in
        case List.length listA of
            2 ->
                div []
                    [ span
                        ([ class "db absolute bt bb b--near-black bg-yellow z-9999 o-70 h1 pa1"
                         , style [ ( "top", "50%" ), ( "left", "50%" ), ( "transform", translate ), ( "cursor", "move" ), ( "width", "141px" ) ]
                         ]
                            ++ (Draggable.mouseTrigger position dragMsg)
                            :: (Draggable.touchTriggers position dragMsg)
                        )
                        [ text "๐ ๐ ๐" ]
                    , div
                        [ class <|
                            "flex justify-center justify-start-ns flex-wrap absolute mw6 "
                                ++ "f7 fw1 ba b--near-black bg-dark-gray2 z-999 o-90 pt4"
                        , style [ ( "top", "50%" ), ( "left", "50%" ), ( "transform", translate ) ]
                        ]
                        (List.map shortChoices listA)
                    ]

            26 ->
                div []
                    [ span
                        ([ class "db absolute bt bb b--near-black bg-light-yellow z-9999 o-70 h1 pa1"
                         , style [ ( "top", "50%" ), ( "left", "50%" ), ( "transform", translate ), ( "cursor", "move" ), ( "width", "247px" ) ]
                         ]
                            ++ (Draggable.mouseTrigger position dragMsg)
                            :: (Draggable.touchTriggers position dragMsg)
                        )
                        [ text "๐ ๐ ๐" ]
                    , div
                        [ class <|
                            "flex justify-center flex-wrap absolute w5 "
                                ++ "f7 fw1 ba b--near-black bg-dark-gray2 z-999 o-90 pt4"
                        , style [ ( "top", "50%" ), ( "left", "50%" ), ( "transform", translate ) ]
                        ]
                        (List.map longChoices listA)
                    ]

            _ ->
                Debug.log "Unexpected list of choices" <| text (toString listA)
