module Board exposing (Msg(..), view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Item


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
    = Index Int Int


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


view : Item.Model -> Html Msg
view items =
    let
        desc : String -> String -> String -> Html msg
        desc p1 p2 p3 =
            div [ class "aspect-ratio--object flex flex-column justify-center" ]
                [ p [ class "dn db-ns ma0 f8 lh-solid" ] [ text p1 ]
                , p [ class "db ma0 f6 f5-ns lh-solid" ] [ text p2 ]
                , p [ class "dn db-ns ma0 f8 lh-solid" ] [ text p3 ]
                ]

        slot : Int -> Int -> String -> List (Html Msg) -> Html Msg
        slot i j colour body =
            div
                [ class <| colour ++ " dtc tc ba b--silver"
                , onClick <| Index i j
                ]
                [ div [ class "aspect-ratio aspect-ratio--1x1" ] body ]

        viewSlot : Int -> Int -> Multiplier -> Html Msg
        viewSlot i j multiplier =
            case multiplier of
                E3 ->
                    slot i j "bg-red" [ desc "TRIPPLE" "3X" "Equation" ]

                E2 ->
                    slot i j "bg-yellow" [ desc "DOUBLE" "2X" "Equation" ]

                P3 ->
                    slot i j "bg-blue" [ desc "TRIPPLE" "3X" "PIECE" ]

                P2 ->
                    slot i j "bg-orange" [ desc "DOUBLE" "2X" "PIECE" ]

                X1 ->
                    slot i j "bg-gray2" []

                X_ ->
                    slot i j "bg-mid-gray2" []

        row : Int -> List Multiplier -> Html Msg
        row i cols =
            div [ class "dt dt--fixed" ] (List.indexedMap (viewSlot i) cols)
    in
        section [ class "avenir" ] (List.indexedMap row board)
