module Board exposing (Msg(..), view, tileSide)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)


{- We define a board as a list of lists just because we want elm-format
   not to wrap elements to eternity. We sacrifice on performance a little.

   Board Data
   E3: 3X where X is a equation score
   E2: 2X where X is a equation score
   P3: 3X where X is a piece score
   P2: 2X where X is a piece score
   X1: identity score
   X_: The star (also identity score)
-}


type Multiplier
    = E3
    | E2
    | P3
    | P2
    | X1
    | X_


type Msg
    = Index ( Int, Int )


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


tileSide : Int
tileSide =
    40


boardSize : Int
boardSize =
    List.length board
        |> toFloat
        |> sqrt
        |> round


viewBoard : Int -> Int -> Multiplier -> Html Msg
viewBoard i j multiplier =
    let
        bonus : String -> List (Html Msg) -> Html Msg
        bonus colour body =
            div
                [ class <| colour ++ " dtc tc ba b--light-gray"
                , onClick <| Index ( i, j )
                ]
                [ div [ class "aspect-ratio aspect-ratio--1x1" ] body ]

        desc : String -> String -> String -> Html Msg
        desc p1 p2 p3 =
            div [ class "aspect-ratio--object flex flex-column justify-center" ]
                [ p [ class "dn db-ns ma0 f8 lh-solid" ] [ text p1 ]
                , p [ class "db ma0 f6 f5-ns lh-solid" ] [ text p2 ]
                , p [ class "dn db-ns ma0 f8 lh-solid" ] [ text p3 ]
                ]
    in
        case multiplier of
            E3 ->
                bonus "bg-red" [ desc "TRIPPLE" "3X" "Equation" ]

            E2 ->
                bonus "bg-yellow" [ desc "DOUBLE" "2X" "Equation" ]

            P3 ->
                bonus "bg-blue" [ desc "TRIPPLE" "3X" "PIECE" ]

            P2 ->
                bonus "bg-orange" [ desc "DOUBLE" "2X" "PIECE" ]

            X1 ->
                bonus "bg-navy" []

            X_ ->
                bonus "bg-silver" []


view : Html Msg
view =
    let
        row : Int -> List Multiplier -> Html Msg
        row i slots =
            div [ class "dt dt--fixed" ] (List.indexedMap (viewBoard i) slots)
    in
        section [ class "w-80-m w-40-l avenir" ] (List.indexedMap row board)
