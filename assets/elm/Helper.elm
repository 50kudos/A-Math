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
