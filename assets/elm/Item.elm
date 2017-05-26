module Item exposing (restItems, myItems)

import Json.Decode as JD
import Html exposing (..)
import Html.Attributes exposing (class)


response : String
response =
    """{
      "myItems" : [
        {"item" : "10", "ea" : 1, "point" : 1},
        {"item" : "-", "ea" : 1, "point" : 1},
        {"item" : "=", "ea" : 1, "point" : 1},
        {"item" : "=", "ea" : 1, "point" : 1},
        {"item" : "1", "ea" : 1, "point" : 1},
        {"item" : "2", "ea" : 1, "point" : 1},
        {"item" : "0", "ea" : 1, "point" : 1},
        {"item" : "9", "ea" : 1, "point" : 1}
      ],
      "restItems" : [
        {"item" : "0", "ea" : 4, "point" : 1},
        {"item" : "1", "ea" : 5, "point" : 1},
        {"item" : "2", "ea" : 5, "point" : 1},
        {"item" : "3", "ea" : 5, "point" : 1},
        {"item" : "4", "ea" : 5, "point" : 2},
        {"item" : "5", "ea" : 4, "point" : 2},
        {"item" : "6", "ea" : 4, "point" : 2},
        {"item" : "7", "ea" : 4, "point" : 2},
        {"item" : "8", "ea" : 4, "point" : 2},
        {"item" : "9", "ea" : 3, "point" : 2},
        {"item" : "10", "ea" : 1, "point" : 3},
        {"item" : "11", "ea" : 1, "point" : 4},
        {"item" : "12", "ea" : 2, "point" : 3},
        {"item" : "13", "ea" : 1, "point" : 6},
        {"item" : "14", "ea" : 1, "point" : 4},
        {"item" : "15", "ea" : 1, "point" : 4},
        {"item" : "16", "ea" : 1, "point" : 4},
        {"item" : "17", "ea" : 1, "point" : 6},
        {"item" : "18", "ea" : 1, "point" : 4},
        {"item" : "19", "ea" : 1, "point" : 7},
        {"item" : "20", "ea" : 1, "point" : 5},
        {"item" : "+", "ea" : 4, "point" : 2},
        {"item" : "-", "ea" : 3, "point" : 2},
        {"item" : "+/-", "ea" : 5, "point" : 1},
        {"item" : "x", "ea" : 4, "point" : 2},
        {"item" : "÷", "ea" : 4, "point" : 2},
        {"item" : "x/÷", "ea" : 4, "point" : 1},
        {"item" : "=", "ea" : 9, "point" : 1},
        {"item" : "", "ea" : 4, "point" : 0}
      ]
    }
    """


type alias State =
    { myItems : List Item
    , restItems : List Item
    }


type alias Item =
    { item : String
    , ea : Int
    , point : Int
    }


itemDecoder : JD.Decoder Item
itemDecoder =
    JD.map3 Item
        (JD.field "item" JD.string)
        (JD.field "ea" JD.int)
        (JD.field "point" JD.int)


initialItems : String -> List Item
initialItems itemsKey =
    case JD.decodeString (JD.at [ itemsKey ] <| JD.list itemDecoder) response of
        Ok items ->
            items

        Err _ ->
            []


initialState : State
initialState =
    { myItems = initialItems "myItems", restItems = initialItems "restItems" }


xy_center : String
xy_center =
    "flex justify-center items-center"


myItems : Html msg
myItems =
    let
        tile : Item -> Html msg
        tile item =
            div
                [ class ("bg-dark-blue light-gray mh1 w2 h2 " ++ xy_center) ]
                [ text item.item
                , sub [ class "f8 fw5 moon-gray" ] [ text "1" ]
                ]
    in
        div [ class <| xy_center ++ " mt4" ]
            (List.map tile initialState.myItems)


restItems : Html msg
restItems =
    let
        tile : Item -> Html msg
        tile item =
            div [ class <| "mb1 " ++ xy_center ]
                [ div [ class <| "bg-dark-blue light-gray w2 h2 " ++ xy_center ]
                    [ text item.item ]
                , span [ class "w1 tc silver pl1" ] [ text (toString item.ea) ]
                ]
    in
        section
            [ class
                "dn flex-ns flex-wrap flex-column-l mw5-l mb4 ph5 ph3-l w-100 vh-50-l"
            ]
            (List.map tile initialState.restItems)
