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
