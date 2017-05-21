module Board exposing (Msg(..), view)

import Svg
import Svg.Attributes as SvgAttrs
import Svg.Events as SvgEvents


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


tileSide : Int
tileSide =
    40


boardSize : Int
boardSize =
    List.length board
        |> toFloat
        |> sqrt
        |> round


viewSvg : Int -> Multiplier -> Svg.Svg Msg
viewSvg n multiplier =
    let
        ( i, j ) =
            ( (n // boardSize), (rem n boardSize) )

        xCenter =
            toString (toFloat (j * tileSide) + (toFloat tileSide + 1) / 2)

        rect_ =
            \colour labelMiddle labelTop labelBottom ->
                Svg.a [ SvgEvents.onClick (Index ( i, j )), SvgAttrs.style "cursor: pointer;" ]
                    [ Svg.rect
                        [ SvgAttrs.width (toString (tileSide - 1))
                        , SvgAttrs.height (toString (tileSide - 1))
                        , SvgAttrs.fill colour
                        , SvgAttrs.x (toString (j * tileSide + 1))
                        , SvgAttrs.y (toString (i * tileSide + 1))
                        ]
                        []
                    , Svg.text_
                        [ SvgAttrs.x xCenter
                        , SvgAttrs.y (toString (i * tileSide + 5))
                        , SvgAttrs.fill "black"
                        , SvgAttrs.fontSize "7"
                        , SvgAttrs.textAnchor "middle"
                        , SvgAttrs.alignmentBaseline "hanging"
                        ]
                        [ Svg.text labelTop ]
                    , Svg.text_
                        [ SvgAttrs.x xCenter
                        , SvgAttrs.y (toString (i * tileSide + tileSide // 2))
                        , SvgAttrs.fill "black"
                        , SvgAttrs.textAnchor "middle"
                        , SvgAttrs.alignmentBaseline "central"
                        ]
                        [ Svg.text labelMiddle ]
                    , Svg.text_
                        [ SvgAttrs.x xCenter
                        , SvgAttrs.y (toString ((i * tileSide - 5) + tileSide))
                        , SvgAttrs.fill "black"
                        , SvgAttrs.fontSize "7"
                        , SvgAttrs.textAnchor "middle"
                        , SvgAttrs.alignmentBaseline "baseline"
                        ]
                        [ Svg.text labelBottom ]
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


view : Svg.Svg Msg
view =
    Svg.svg
        [ SvgAttrs.width (toString (15 * tileSide))
        , SvgAttrs.height (toString (15 * tileSide))
        ]
        (List.indexedMap viewSvg board)
