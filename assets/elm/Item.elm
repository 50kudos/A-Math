module Item exposing (Model, Msg(..), myItems, restItems, getItems)

import Json.Decode as JD
import Html exposing (..)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Http


type alias Model =
    { myItems : List Item
    , restItems : List Item
    }


type alias Item =
    { item : String
    , ea : Int
    , point : Int
    }


type Msg
    = Fetch (Result Http.Error Model)
    | Pick Int


getItems : Cmd Msg
getItems =
    let
        itemListDecoder : JD.Decoder (List Item)
        itemListDecoder =
            JD.list <|
                JD.map3 Item
                    (JD.field "item" JD.string)
                    (JD.field "ea" JD.int)
                    (JD.field "point" JD.int)

        decoder : JD.Decoder Model
        decoder =
            JD.map2 Model
                (JD.at [ "myItems" ] itemListDecoder)
                (JD.at [ "restItems" ] itemListDecoder)
    in
        Http.send Fetch <|
            Http.get "http://localhost:4000/api/items/3" decoder


myItems : Model -> Html Msg
myItems model =
    let
        tile : Int -> Item -> Html Msg
        tile nth item =
            div
                [ class <| xy_center ++ " bg-dark-blue light-gray mh1 w2 h2 pointer relative"
                , onClick (Pick nth)
                ]
                [ span [] [ text item.item ]
                , sub [ class "f8 fw5 moon-gray" ] [ text (toString item.point) ]
                ]
    in
        div [ class <| xy_center ++ " mv2 mv4-ns" ]
            (List.indexedMap tile model.myItems)


restItems : Model -> Html msg
restItems model =
    let
        tile : Item -> Html msg
        tile item =
            div [ class <| "mb1 " ++ xy_center ]
                [ div [ class <| "bg-dark-blue light-gray w2 h2 " ++ xy_center ]
                    [ text item.item ]
                , span [ class "w1 tc silver pl1" ] [ text (toString item.ea) ]
                ]
    in
        section
            [ class
                "dn flex-ns flex-wrap flex-column-l mw5-l mb4 ph5 ph3-l w-100 vh-50-l"
            ]
            (List.map tile model.restItems)



-- Helper functions


xy_center : String
xy_center =
    "flex justify-center items-center"
