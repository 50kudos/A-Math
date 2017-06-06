module Game exposing (..)

import Item
import Board
import Html exposing (Html, div, map, section, button, a, text)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Http
import Json.Decode as JD


type alias Model =
    { items : Item.Model
    , board : Board.Model
    }


type Msg
    = Fetch (Result Http.Error Model)
    | Push
    | ItemMsg Item.Msg
    | BoardMsg Board.Msg


type Source
    = FromBoard ( String, Int )
    | FromDeck ( String, Int )


type Destination
    = ToBoard
    | ToDeck


init : Model
init =
    Model Item.init Board.init


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ItemMsg msg ->
            case toMove ToDeck model of
                FromBoard item ->
                    case Item.recallItem msg item model.items of
                        Ok items ->
                            { model
                                | items = items
                                , board = Board.hideMovedItem model.board
                            }
                                ! [ Cmd.none ]

                        Err _ ->
                            model ! [ Cmd.none ]

                FromDeck _ ->
                    { model | items = Item.update msg model.items } ! [ Cmd.none ]

        BoardMsg msg ->
            case toMove ToBoard model of
                FromDeck item ->
                    case Board.addItem msg item model.board of
                        Ok board ->
                            { model
                                | board = board
                                , items =
                                    Item.hideMovedItem model.items
                            }
                                ! [ Cmd.none ]

                        Err _ ->
                            model ! [ Cmd.none ]

                FromBoard _ ->
                    { model | board = Board.update msg model.board } ! [ Cmd.none ]

        Fetch (Ok gameData) ->
            { model | items = gameData.items, board = gameData.board } ! [ Cmd.none ]

        Fetch (Err error) ->
            Debug.log (toString error) model ! [ Cmd.none ]

        Push ->
            let
                jsonBody =
                    Http.jsonBody (Board.encoder model.board)
            in
                ( model, patchItems jsonBody )


toMove : Destination -> Model -> Source
toMove move_ { items, board } =
    case move_ of
        ToBoard ->
            case List.filter .picked items.myItems of
                [ pickedItem ] ->
                    FromDeck ( pickedItem.item, pickedItem.point )

                _ ->
                    FromBoard ( "", 0 )

        ToDeck ->
            case List.filter .picked board.stagingItems of
                [ pickedItem ] ->
                    FromBoard ( pickedItem.item, pickedItem.point )

                _ ->
                    FromDeck ( "", 0 )


view : Model -> Html Msg
view model =
    div [ class "flex justify-center flex-wrap pv4" ]
        [ Item.restItems model.items
        , section [ class "w-80-m w-40-l" ]
            [ Board.view model.board BoardMsg
            , Item.myItems model.items ItemMsg
            ]
        , section [ class "pl3" ]
            [ a
                [ class "f6 link db br1 ba ph3 pv2 near-white pointer"
                , onClick Push
                ]
                [ text "Submit" ]
            ]
        ]


decoder : JD.Decoder Model
decoder =
    JD.map2 Model
        (Item.decoder)
        (Board.decoder)


getItems : Cmd Msg
getItems =
    Http.send Fetch <|
        Http.get "http://localhost:4000/api/items/10" decoder


patchItems : Http.Body -> Cmd Msg
patchItems body =
    Http.send Fetch <|
        Http.request
            { method = "PATCH"
            , headers = []
            , url = "http://localhost:4000/api/items/10"
            , body = body
            , expect = Http.expectJson decoder
            , timeout = Nothing
            , withCredentials = False
            }
