module Main exposing (..)

import Html exposing (..)
import Svg exposing (Svg)
import Svg.Attributes exposing (..)
import Svg.Events exposing (onClick)


type alias Model =
    ( Int, Int )


type TileClick a
    = Index ( Int, Int )


model : Model
model =
    ( 0, 0 )


update : TileClick a -> Model -> Model
update msg model =
    case msg of
        Index ( i, j ) ->
            ( i, j )



-- Board Data
--
-- E3: 3X where X is a equation score
-- E2: 2X where X is a equation score
-- P3: 3X where X is a piece score
-- P2: 2X where X is a piece score
-- X1: identity score
-- X_: The star (also identity score)


type Multiplier
    = E3
    | E2
    | P3
    | P2
    | X1
    | X_



{- We define a board as a list of lists just because we want elm-format
   not to wrap elements to eternity. We sacrifice on performance a little.
-}


board : List Multiplier
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
        |> List.concat


boardSize : Int
boardSize =
    List.length board
        |> toFloat
        |> sqrt
        |> round


tileSide : Int
tileSide =
    40



--
-- Board Views


viewSvg : Int -> Multiplier -> Svg (TileClick a)
viewSvg n multiplier =
    let
        ( i, j ) =
            ( (n // boardSize), (rem n boardSize) )

        xCenter =
            toString (toFloat (j * tileSide) + (toFloat tileSide + 1) / 2)

        rect_ =
            \colour labelMiddle labelTop labelBottom ->
                Svg.a [ onClick (Index ( i, j )), style "cursor: pointer;" ]
                    [ Svg.rect
                        [ width (toString (tileSide - 1))
                        , height (toString (tileSide - 1))
                        , fill colour
                        , x (toString (j * tileSide + 1))
                        , y (toString (i * tileSide + 1))
                        ]
                        []
                    , Svg.text_
                        [ x xCenter
                        , y (toString (i * tileSide + 5))
                        , fill "black"
                        , fontSize "7"
                        , textAnchor "middle"
                        , alignmentBaseline "hanging"
                        ]
                        [ text labelTop ]
                    , Svg.text_
                        [ x xCenter
                        , y (toString (i * tileSide + tileSide // 2))
                        , fill "black"
                        , textAnchor "middle"
                        , alignmentBaseline "central"
                        ]
                        [ text labelMiddle ]
                    , Svg.text_
                        [ x xCenter
                        , y (toString ((i * tileSide - 5) + tileSide))
                        , fill "black"
                        , fontSize "7"
                        , textAnchor "middle"
                        , alignmentBaseline "baseline"
                        ]
                        [ text labelBottom ]
                    ]
    in
        case multiplier of
            E3 ->
                rect_ "crimson" "3X" "TRIPPLE" "EQUATION"

            E2 ->
                rect_ "gold" "2X" "DOUBLE" "EQUATION"

            P3 ->
                rect_ "dodgerblue" "3X" "TRIPPLE" "PIECE"

            P2 ->
                rect_ "darkorange" "2X" "DOUBLE" "PIECE"

            X1 ->
                rect_ "darkgreen" "" "" ""

            X_ ->
                rect_ "#333333" "" "" ""


viewBoard : Html (TileClick a)
viewBoard =
    Svg.svg
        [ width (toString (15 * tileSide))
        , height (toString (15 * tileSide))
        ]
        (List.indexedMap viewSvg board)


view : Model -> Html (TileClick a)
view model =
    viewBoard


main : Program Never Model (TileClick a)
main =
    Html.beginnerProgram
        { model = model
        , view = view
        , update = update
        }
