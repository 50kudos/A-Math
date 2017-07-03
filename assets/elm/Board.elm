module Board
    exposing
        ( Model
        , Msg
        , CommittedItem
        , init
        , update
        , addItem
        , hideMovedItem
        , clearStaging
        , markChoice
        , view
        , committedItemsDecoder
        , encoder
        )

import Html exposing (..)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Json.Decode as JD
import Json.Encode as JE
import List.Extra
import Helper as H


type alias Model =
    { committedItems : List CommittedItem
    , stagingItems : List (StagingItem CommittedItem)
    }


type alias CommittedItem =
    { item : String, i : Int, j : Int, point : Int, value : String }


type alias StagingItem a =
    { a | picked : Bool }


type Multiplier
    = E3
    | E2
    | P3
    | P2
    | X1
    | X_


type Msg
    = Pick (StagingItem CommittedItem)
    | Put Int Int
    | Nope


init : Model
init =
    Model [] []


update : Msg -> Model -> Model
update msg model =
    case msg of
        Pick { i, j } ->
            let
                shouldPick : { a | picked : Bool } -> Bool
                shouldPick { picked } =
                    if otherBeingPicked model i j then
                        False
                    else
                        not picked
            in
                { model
                    | stagingItems =
                        model.stagingItems
                            |> List.Extra.updateIf (H.isAtIndex i j)
                                (\item -> { item | picked = shouldPick item })
                }

        Put i j ->
            case List.partition .picked model.stagingItems of
                ( [ pickedItem ], restItems ) ->
                    let
                        movedItem =
                            { pickedItem | i = i, j = j, picked = False }
                    in
                        { model | stagingItems = movedItem :: restItems }

                ( _, _ ) ->
                    model

        Nope ->
            model


addItem : Msg -> ( String, Int ) -> Model -> Result Model Model
addItem msg ( item, point ) model =
    case msg of
        Put i j ->
            Ok
                { model
                    | stagingItems =
                        { item = item, i = i, j = j, picked = False, point = point, value = item } :: model.stagingItems
                }

        _ ->
            Err model


hideMovedItem : Model -> Model
hideMovedItem model =
    { model | stagingItems = List.filter (not << .picked) model.stagingItems }


clearStaging : Model -> Model
clearStaging model =
    { model | stagingItems = [] }


otherBeingPicked : Model -> Int -> Int -> Bool
otherBeingPicked { stagingItems } i j =
    stagingItems
        |> List.any (\item -> not (H.isAtIndex i j item) && item.picked)


markChoice : Int -> Int -> String -> Model -> Model
markChoice i j strItem model =
    { model
        | stagingItems =
            List.map
                (\item ->
                    if item.i == i && item.j == j then
                        { item | value = strItem }
                    else
                        item
                )
                model.stagingItems
    }


board : List (List Multiplier)
board =
    [ [ E3, X1, X1, P2, X1, X1, X1, E3, X1, X1, X1, P2, X1, X1, E3 ]
    , [ X1, E2, X1, X1, X1, P3, X1, X1, X1, P3, X1, X1, X1, E2, X1 ]
    , [ X1, X1, E2, X1, X1, X1, P2, X1, P2, X1, X1, X1, E2, X1, X1 ]
    , [ P2, X1, X1, E2, X1, X1, X1, P2, X1, X1, X1, E2, X1, X1, P2 ]
    , [ X1, X1, X1, X1, P3, X1, X1, X1, X1, X1, P3, X1, X1, X1, X1 ]
    , [ X1, P3, X1, X1, X1, P3, X1, X1, X1, P3, X1, X1, X1, P3, X1 ]
    , [ X1, X1, P2, X1, X1, X1, P2, X1, P2, X1, X1, X1, P2, X1, X1 ]
    , [ E3, X1, X1, P2, X1, X1, X1, X_, X1, X1, X1, P2, X1, X1, E3 ]
    , [ X1, X1, P2, X1, X1, X1, P2, X1, P2, X1, X1, X1, P2, X1, X1 ]
    , [ X1, P3, X1, X1, X1, P3, X1, X1, X1, P3, X1, X1, X1, P3, X1 ]
    , [ X1, X1, X1, X1, P3, X1, X1, X1, X1, X1, P3, X1, X1, X1, X1 ]
    , [ P2, X1, X1, E2, X1, X1, X1, P2, X1, X1, X1, E2, X1, X1, P2 ]
    , [ X1, X1, E2, X1, X1, X1, P2, X1, P2, X1, X1, X1, E2, X1, X1 ]
    , [ X1, E2, X1, X1, X1, P3, X1, X1, X1, P3, X1, X1, X1, E2, X1 ]
    , [ E3, X1, X1, P2, X1, X1, X1, E3, X1, X1, X1, P2, X1, X1, E3 ]
    ]


view : Maybe ( x, Int, Int ) -> Model -> (Msg -> msg) -> Html msg
view choice model toMsg =
    let
        slot : Msg -> String -> List (Html Msg) -> Html Msg
        slot msg colour body =
            div
                [ class <| colour ++ " dtc tc ba b--silver"
                , onClick msg
                ]
                [ div [ class "aspect-ratio aspect-ratio--1x1" ] body ]

        desc : String -> String -> String -> Html Msg
        desc p1 p2 p3 =
            div [ class "aspect-ratio--object flex flex-column justify-center" ]
                [ p [ class "dn db-ns ma0 f8 lh-solid" ] [ text p1 ]
                , p [ class "db ma0 f7 f5-ns lh-solid" ] [ text p2 ]
                , p [ class "dn db-ns ma0 f8 lh-solid" ] [ text p3 ]
                ]

        viewSlot : Int -> Int -> Multiplier -> Html Msg
        viewSlot i j multiplier =
            case List.Extra.find (H.isAtIndex i j) model.committedItems of
                Just item ->
                    slot Nope "bg-dark-blue br2 light-gray b--black-0125" [ desc "" (H.castChoice item.item item.value) "" ]

                Nothing ->
                    case List.Extra.find (H.isAtIndex i j) model.stagingItems of
                        Just item ->
                            slot (Pick item)
                                ((H.colorByPick item) ++ "pointer" ++ (H.slotHeighlight i j choice))
                                [ desc "" (H.cast item.item) "" ]

                        Nothing ->
                            case multiplier of
                                E3 ->
                                    slot (Put i j) "bg-red dark-gray" [ desc "TRIPPLE" "3X" "Equation" ]

                                E2 ->
                                    slot (Put i j) "bg-yellow dark-gray" [ desc "DOUBLE" "2X" "Equation" ]

                                P3 ->
                                    slot (Put i j) "bg-blue dark-gray" [ desc "TRIPPLE" "3X" "PIECE" ]

                                P2 ->
                                    slot (Put i j) "bg-orange dark-gray" [ desc "DOUBLE" "2X" "PIECE" ]

                                X1 ->
                                    slot (Put i j) "bg-gray2 dark-gray" []

                                X_ ->
                                    slot (Put i j) "bg-mid-gray2 dark-gray" []

        row : Int -> List Multiplier -> Html Msg
        row i cols =
            div [ class "dt dt--fixed" ] (List.indexedMap (viewSlot i) cols)
    in
        map toMsg <|
            section [ class "avenir" ] (List.indexedMap row board)


committedItemsDecoder : JD.Decoder CommittedItem
committedItemsDecoder =
    JD.map5 CommittedItem
        (JD.field "item" JD.string)
        (JD.field "i" JD.int)
        (JD.field "j" JD.int)
        (JD.field "point" JD.int)
        (JD.field "value" JD.string)


encoder : Model -> JE.Value
encoder { stagingItems } =
    let
        encodeItem : StagingItem CommittedItem -> JE.Value
        encodeItem { item, i, j, point, value } =
            JE.object
                [ ( "item", JE.string item )
                , ( "i", JE.int i )
                , ( "j", JE.int j )
                , ( "point", JE.int point )
                , ( "value", JE.string value )
                ]
    in
        JE.object
            [ ( "items"
              , JE.object
                    [ ( "boardItems", JE.list <| List.map encodeItem stagingItems )
                    ]
              )
            ]
