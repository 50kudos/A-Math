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
    , choices : List ( String, Int, Int )
    }


type Msg
    = Fetch (Result Http.Error Model)
    | Patch (Result Http.Error Model)
    | Exchange
    | Push
    | ItemMsg Item.Msg
    | BoardMsg Board.Msg
    | BatchRecall
    | EnqueueChoices (List ( String, Int, Int ))
    | SelectChoice Int Int String


type Choice
    = PlusMinus
    | MultiplyDivive
    | Blank


type Source
    = FromBoard ( String, Int )
    | FromDeck ( String, Int )


type Destination
    = ToBoard
    | ToDeck


init : Model
init =
    Model Item.init Board.init []


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( model.choices, msg ) of
        ( [], _ ) ->
            normalUpdate msg model

        ( _, SelectChoice _ _ _ ) ->
            normalUpdate msg model

        ( _, _ ) ->
            ( model, Cmd.none )


normalUpdate : Msg -> Model -> ( Model, Cmd Msg )
normalUpdate msg model =
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

        Patch (Ok gameData) ->
            if
                Board.commitUnchanged model.board gameData.board
                    && not (Board.exchanged model.board gameData.board)
            then
                model ! [ Cmd.none ]
            else
                { model | items = gameData.items, board = gameData.board } ! [ Cmd.none ]

        Patch (Err error) ->
            Debug.log (toString error) model ! [ Cmd.none ]

        Fetch (Ok gameData) ->
            { model | items = gameData.items, board = gameData.board } ! [ Cmd.none ]

        Fetch (Err error) ->
            Debug.log (toString error) model ! [ Cmd.none ]

        Push ->
            let
                jsonBody =
                    Http.jsonBody (Board.encoder "commit" model.board)
            in
                ( model, patchItems jsonBody )

        EnqueueChoices forPosition ->
            { model | choices = forPosition } ! [ Cmd.none ]

        SelectChoice i j item ->
            let
                model_ =
                    { model
                        | board = Board.markChoice i j item model.board
                        , choices = List.drop 1 model.choices
                    }
            in
                case model_.choices of
                    [] ->
                        normalUpdate Push model_

                    _ ->
                        ( model_, Cmd.none )

        Exchange ->
            let
                jsonBody =
                    Http.jsonBody (Board.encoder "exchange" model.board)
            in
                ( model, patchItems jsonBody )

        BatchRecall ->
            { model
                | items = Item.batchRecall model.items
                , board = Board.clearStaging model.board
            }
                ! [ Cmd.none ]


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


beforeSubmit : Model -> Msg
beforeSubmit model =
    let
        filterChoicable : Board.Model -> List ( String, Int, Int )
        filterChoicable board =
            board.stagingItems
                |> List.filter (\item -> List.member item.item [ "blank", "+/-", "x/÷" ])
                |> List.map (\item -> ( item.item, item.i, item.j ))
    in
        case filterChoicable model.board of
            [] ->
                Push

            choiceList ->
                EnqueueChoices choiceList


viewChoiceFor : Maybe ( String, Int, Int ) -> Model -> Html Msg
viewChoiceFor position model =
    case position of
        Just ( item, i, j ) ->
            case item of
                "blank" ->
                    Item.viewChoices (SelectChoice i j) (Item.itemChoices model.items)

                "+/-" ->
                    Item.viewChoices (SelectChoice i j) [ "+", "-" ]

                "x/÷" ->
                    Item.viewChoices (SelectChoice i j) [ "x", "÷" ]

                _ ->
                    Debug.crash "Unexpected selectable item occurs."

        Nothing ->
            text ""


view : Model -> Html Msg
view model =
    div [ class "flex justify-center flex-wrap pv4" ]
        [ Item.restItems model.items
        , section [ class "w-80-m w-40-l" ]
            [ div [ class "relative" ]
                [ Board.view (List.head model.choices) model.board BoardMsg
                , viewChoiceFor (List.head model.choices) model
                ]
            , div [ class "flex justify-center  mt2 mt4-ns" ]
                [ Item.myItems model.items ItemMsg
                , a
                    [ class "f6 link br1 ba ph3 pv2 near-white pointer tc"
                    , onClick BatchRecall
                    ]
                    [ text "recall" ]
                ]
            ]
        , section [ class "pl3" ]
            [ a
                [ class "f6 link db br1 ba ph3 pv2 near-white pointer"
                , onClick (beforeSubmit model)
                ]
                [ text "Submit" ]
            , a
                [ class "mt2 f6 link db br1 ba ph3 pv2 near-white pointer"
                , onClick Exchange
                ]
                [ text "Exchange" ]
            ]
        ]


decoder : JD.Decoder Model
decoder =
    JD.map3 Model
        (Item.decoder)
        (Board.decoder)
        (JD.succeed [])


getItems : Cmd Msg
getItems =
    Http.send Fetch <|
        Http.get "http://localhost:4000/api/items/10" decoder


patchItems : Http.Body -> Cmd Msg
patchItems body =
    Http.send Patch <|
        Http.request
            { method = "PATCH"
            , headers = []
            , url = "http://localhost:4000/api/items/10"
            , body = body
            , expect = Http.expectJson decoder
            , timeout = Nothing
            , withCredentials = False
            }
