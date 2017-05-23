module Item exposing (view, digit, tenDigit, operators, myItems)

import Json.Decode as JD
import Svg
import Svg.Attributes as SvgAttrs


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
        {"item" : "+-", "ea" : 5, "point" : 1},
        {"item" : "*", "ea" : 4, "point" : 2},
        {"item" : "/", "ea" : 4, "point" : 2},
        {"item" : "*/", "ea" : 4, "point" : 1},
        {"item" : "=", "ea" : 9, "point" : 1},
        {"item" : "blank", "ea" : 4, "point" : 0}
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


digit : Svg.Svg msg
digit =
    initialState.restItems |> List.take 10 |> view


tenDigit : Svg.Svg msg
tenDigit =
    initialState.restItems |> List.drop 10 |> List.take 10 |> view


operators : Svg.Svg msg
operators =
    initialState.restItems |> List.drop 20 |> view


myItems : Svg.Svg msg
myItems =
    initialState.myItems |> viewMyItems


item : Int -> Int -> Item -> Svg.Svg msg
item x_ y_ item =
    let
        ( x, y ) =
            ( toFloat x_, toFloat y_ )

        side =
            40
    in
        Svg.g []
            [ Svg.rect
                [ SvgAttrs.width (toString side)
                , SvgAttrs.height (toString side)
                , SvgAttrs.fill "blue"
                , SvgAttrs.x (toString x)
                , SvgAttrs.y (toString y)
                ]
                []
            , Svg.text_
                [ SvgAttrs.x (toString <| x + side / 2)
                , SvgAttrs.y (toString <| y + side / 2)
                , SvgAttrs.fill "white"
                , SvgAttrs.textAnchor "middle"
                , SvgAttrs.alignmentBaseline "central"
                ]
                [ Svg.text item.item ]
            ]


viewMyItems : List Item -> Svg.Svg msg
viewMyItems items =
    let
        tile =
            \i t ->
                Svg.g []
                    [ Svg.rect
                        [ SvgAttrs.width "39"
                        , SvgAttrs.height "39"
                        , SvgAttrs.fill "blue"
                        , SvgAttrs.x "0"
                        , SvgAttrs.y (toString (i * 40 + 1))
                        ]
                        []
                    , Svg.text_
                        [ SvgAttrs.x (toString 20)
                        , SvgAttrs.y (toString (i * 40 + 40 // 2))
                        , SvgAttrs.fill "white"
                        , SvgAttrs.textAnchor "middle"
                        , SvgAttrs.alignmentBaseline "central"
                        ]
                        [ Svg.text t.item ]
                    ]
    in
        Svg.svg
            [ SvgAttrs.width (toString 70)
            , SvgAttrs.height (toString (15 * 40))
            ]
            (List.indexedMap tile items)


view : List Item -> Svg.Svg msg
view items =
    let
        tile =
            \i t ->
                Svg.g []
                    [ item 0 (40 * i + i) t
                    , Svg.rect
                        [ SvgAttrs.width "20"
                        , SvgAttrs.height "39"
                        , SvgAttrs.fill "white"
                        , SvgAttrs.x "40"
                        , SvgAttrs.y (toString <| 41 * i)
                        ]
                        []
                    , Svg.text_
                        [ SvgAttrs.x (toString 50)
                        , SvgAttrs.y (toString (i * 41 + 40 // 2))
                        , SvgAttrs.textAnchor "middle"
                        , SvgAttrs.alignmentBaseline "central"
                        ]
                        [ Svg.text <| toString t.ea ]
                    ]
    in
        Svg.svg
            [ SvgAttrs.width (toString 70)
            , SvgAttrs.height (toString (15 * 40))
            ]
            (List.indexedMap tile items)
