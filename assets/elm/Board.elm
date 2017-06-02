module Board exposing (Model, Msg, init, update, view, decoder)

import Html exposing (..)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Json.Decode as JD


type alias Model =
    { boardItems : List StageItem }


type alias StageItem =
    { item : String, i : Int, j : Int }


type Multiplier
    = E3
    | E2
    | P3
    | P2
    | X1
    | X_


type Msg
    = Index Int Int


init : Model
init =
    Model []


update : Msg -> Model -> Model
update msg model =
    case msg of
        Index int int2 ->
            model


decoder : JD.Decoder Model
decoder =
    let
        boardItemsDecoder : JD.Decoder StageItem
        boardItemsDecoder =
            JD.map3 StageItem
                (JD.field "item" JD.string)
                (JD.field "i" JD.int)
                (JD.field "j" JD.int)
    in
        JD.map Model (JD.at [ "boardItems" ] <| JD.list boardItemsDecoder)


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


view : (Msg -> msg) -> Html msg
view toMsg =
    let
        desc : String -> String -> String -> Html Msg
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
        map toMsg <|
            section [ class "avenir" ] (List.indexedMap row board)
