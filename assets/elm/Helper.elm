module Helper exposing (..)

import Html exposing (Html, text, span, div)
import Html.Attributes exposing (class)


colorByPick : { a | picked : Bool } -> String
colorByPick item =
    if .picked item then
        " bg-light-gray dark-blue "
    else
        " bg-dark-blue light-gray "


colorByPickStaging : { a | picked : Bool } -> String
colorByPickStaging item =
    if .picked item then
        " bg-light-gray dark-blue "
    else
        " bg-dark-green light-gray b--dark-green "


isAtIndex : Int -> Int -> { a | i : Int, j : Int } -> Bool
isAtIndex i j aIndex =
    aIndex.i == i && aIndex.j == j


cast : String -> Html msg
cast string =
    if string == "blank" then
        text ""
    else
        text string


castChoice : String -> String -> Html msg
castChoice item value =
    case item of
        "blank" ->
            span [ class "orange" ] [ text value ]

        "+/-" ->
            if value == "+" then
                div [ class "f7 f5-ns" ]
                    [ span [ class "orange" ] [ text "+" ]
                    , span [] [ text "|-" ]
                    ]
            else
                div [ class "f7 f5-ns" ]
                    [ span [] [ text "+|" ]
                    , span [ class "orange" ] [ text "-" ]
                    ]

        "x/÷" ->
            if value == "x" then
                div [ class "f7 f5-ns" ]
                    [ span [ class "orange" ] [ text "x" ]
                    , span [] [ text "|÷" ]
                    ]
            else
                div [ class "f7 f5-ns" ]
                    [ span [] [ text "x|" ]
                    , span [ class "orange" ] [ text "÷" ]
                    ]

        _ ->
            text item


slotHighlight : a -> b -> Maybe ( x, a, b ) -> String -> String
slotHighlight i j aMaybe default =
    case aMaybe of
        Just ( _, i_, j_ ) ->
            if i_ == i && j_ == j then
                " light-yellow b--light-yellow bg-dark-gray "
            else
                default

        Nothing ->
            default


submitButtonClass : Bool -> String
submitButtonClass enabled =
    if enabled then
        "mv2 f6 link db pv2 pa4-l near-white tc pointer bg-dark-blue hover-bg-blue flex-auto"
    else
        "mv2 f6 link db pv2 pa4-l dark-gray tc bg-gray flex-auto"


exchangeButtonClass : Bool -> String
exchangeButtonClass enabled =
    if enabled then
        "f6 link db ba b--blue blue ph2 pv2 tc pointer hover-bg-light-blue hover-dark-blue"
    else
        "f6 link db ba b--gray gray ph2 pv2 tc"


recallButtonClass : Bool -> String
recallButtonClass enabled =
    if enabled then
        "f6 link db ba ph2 pv2 near-white dim pointer tc"
    else
        "f6 link db ba ph2 pv2 gray  tc"
