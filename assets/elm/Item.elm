module Item exposing (Model, Msg, init, update, decoder, myItems, restItems)

import Html exposing (..)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Json.Decode as JD
import List.Extra


type alias Model =
    { myItems : List DeckItem
    , restItems : List RestItem
    }


type alias DeckItem =
    { item : String, point : Int, picked : Bool }


type alias RestItem =
    { item : String, ea : Int }


type Msg
    = Pick Int


init : Model
init =
    Model [] []


decoder : JD.Decoder Model
decoder =
    let
        myItemsDecoder : JD.Decoder DeckItem
        myItemsDecoder =
            JD.map3 DeckItem
                (JD.field "item" JD.string)
                (JD.field "point" JD.int)
                (JD.succeed False)

        restItemsDecoder : JD.Decoder RestItem
        restItemsDecoder =
            JD.map2 RestItem
                (JD.field "item" JD.string)
                (JD.field "ea" JD.int)
    in
        JD.map2 Model
            (JD.at [ "myItems" ] <| JD.list myItemsDecoder)
            (JD.at [ "restItems" ] <| JD.list restItemsDecoder)


update : Msg -> Model -> Model
update msg model =
    case msg of
        Pick int ->
            { model | myItems = updateDeck int model }


updateDeck : Int -> Model -> List DeckItem
updateDeck target model =
    let
        handlePick : Int -> DeckItem -> DeckItem
        handlePick i item =
            case ( i == target, item.picked ) of
                ( False, _ ) ->
                    item

                ( True, True ) ->
                    { item | picked = not item.picked }

                ( True, False ) ->
                    { item | picked = True }
    in
        case List.Extra.findIndices .picked model.myItems of
            [] ->
                model.myItems
                    |> List.indexedMap handlePick

            [ prevPicked ] ->
                model.myItems
                    |> List.Extra.swapAt prevPicked target
                    |> Maybe.withDefault model.myItems
                    |> List.map (\item -> { item | picked = False })

            _ ->
                model.myItems


myItems : Model -> (Msg -> msg) -> Html msg
myItems { myItems } toMsg =
    let
        isPick : DeckItem -> String
        isPick item =
            if .picked item then
                "top--1"
            else
                ""

        tile : Int -> DeckItem -> Html Msg
        tile nth item =
            div
                [ class <|
                    "bg-dark-blue light-gray mh1 w2 h2 pointer relative"
                        ++ xy_center
                        ++ isPick item
                , onClick (Pick nth)
                ]
                [ span [] [ text item.item ]
                , sub [ class "f8 fw5 moon-gray" ] [ text (toString item.point) ]
                ]
    in
        div [ class <| xy_center ++ " mv2 mv4-ns" ] (List.indexedMap tile myItems)
            |> map toMsg


restItems : Model -> Html msg
restItems { restItems } =
    let
        tile : RestItem -> Html msg
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
            (List.map tile restItems)



-- Helper functions:
-- Functions in this section are used more than once. Any helper function that
-- is only used once still live in the let block of a certain function.


xy_center : String
xy_center =
    " flex justify-center items-center "
