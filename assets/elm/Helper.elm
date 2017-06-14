module Helper exposing (..)


colorByPick : { a | picked : Bool } -> String
colorByPick item =
    if .picked item then
        " bg-light-gray dark-blue "
    else
        " bg-dark-blue light-gray "


isAtIndex : Int -> Int -> { a | i : Int, j : Int } -> Bool
isAtIndex i j aIndex =
    aIndex.i == i && aIndex.j == j


cast : String -> String
cast string =
    if string == "blank" then
        ""
    else
        string


castChoice : String -> String -> String
castChoice item value =
    case item of
        "blank" ->
            value

        "+/-" ->
            value

        "x/÷" ->
            value

        _ ->
            item


slotHeighlight : a -> b -> Maybe ( x, a, b ) -> String
slotHeighlight i j aMaybe =
    case aMaybe of
        Just ( _, i_, j_ ) ->
            if i_ == i && j_ == j then
                " b--light-yellow bg-dark-gray "
            else
                " b--dark-blue "

        Nothing ->
            " b--dark-blue "
