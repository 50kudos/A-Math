module Main exposing (main)

import Html exposing (Html, map, div, a, text, section)
import Html.Events exposing (onClick)
import Html.Attributes exposing (class)
import Phoenix.Socket as Socket
import Phoenix.Channel as Channel
import Phoenix.Push as Pusher
import Json.Encode as JE
import Json.Decode as JD
import Game
import Board
import Item


type alias Flags =
    { gameId : String }


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { game : Game.Model
    , phxSocket : Socket.Socket Msg
    , gameId : String
    }


type Msg
    = GameMsg Game.Msg
    | ItemMsg Item.Msg
    | BoardMsg Board.Msg
    | PhoenixMsg (Socket.Msg Msg)
    | ShowJoinedMessage JE.Value
    | ResetGame
    | Exchange
    | BatchRecall
    | EnqueueChoices (List ( String, Int, Int ))
    | Push
    | PatchResponse JE.Value
    | ReceiveNewState JE.Value


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        ( phxSocket, phxCmd ) =
            joinChannel flags.gameId
    in
        { game = Game.init, phxSocket = phxSocket, gameId = flags.gameId }
            ! [ Cmd.map PhoenixMsg phxCmd
              ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GameMsg msg ->
            let
                ( game, gameCmd ) =
                    Game.update msg model.game

                choices =
                    List.drop 1 game.choices
            in
                case game.choices of
                    [] ->
                        { model | game = game } ! [ Cmd.map GameMsg gameCmd ]

                    _ ->
                        case choices of
                            [] ->
                                update Push { model | game = { game | choices = choices } }

                            _ ->
                                { model | game = { game | choices = choices } } ! [ Cmd.map GameMsg gameCmd ]

        ItemMsg msg ->
            { model | game = Game.updateItems msg model.game } ! [ Cmd.none ]

        BoardMsg msg ->
            { model | game = Game.updateBoard msg model.game } ! [ Cmd.none ]

        PhoenixMsg msg ->
            let
                ( phxSocket, phxCmd ) =
                    Socket.update msg model.phxSocket
            in
                ( { model | phxSocket = phxSocket }
                , Cmd.map PhoenixMsg phxCmd
                )

        ShowJoinedMessage response ->
            case JD.decodeValue Game.decoder response of
                Ok game ->
                    { model | game = game } ! [ Cmd.none ]

                Err error ->
                    Debug.log error ( model, Cmd.none )

        ResetGame ->
            let
                reqBody =
                    (Board.encoder model.game.board)

                ( phxSocket, phxCmd ) =
                    Socket.push (patchItems "reset" model.gameId reqBody) model.phxSocket
            in
                ( { model | phxSocket = phxSocket }, Cmd.map PhoenixMsg phxCmd )

        PatchResponse response ->
            case JD.decodeValue Game.decoder response of
                Ok gameData ->
                    if
                        Board.commitUnchanged model.game.board gameData.board
                            && not (Board.exchanged model.game.board gameData.board)
                    then
                        model ! [ Cmd.none ]
                    else
                        { model | game = gameData } ! [ Cmd.none ]

                Err error ->
                    Debug.log error ( model, Cmd.none )

        EnqueueChoices forPosition ->
            let
                game =
                    model.game

                updatedGame =
                    { game | choices = forPosition }
            in
                { model | game = updatedGame } ! [ Cmd.none ]

        Exchange ->
            let
                reqBody =
                    (Board.encoder model.game.board)

                ( phxSocket, phxCmd ) =
                    Socket.push (patchItems "exchange" model.gameId reqBody) model.phxSocket
            in
                ( { model | phxSocket = phxSocket }, Cmd.map PhoenixMsg phxCmd )

        Push ->
            let
                reqBody =
                    (Board.encoder model.game.board)

                ( phxSocket, phxCmd ) =
                    Socket.push (patchItems "commit" model.gameId reqBody) model.phxSocket
            in
                ( { model | phxSocket = phxSocket }, Cmd.map PhoenixMsg phxCmd )

        BatchRecall ->
            let
                game =
                    model.game

                game_ =
                    { game
                        | items = Item.batchRecall game.items
                        , board = Board.clearStaging game.board
                    }
            in
                { model | game = game_ }
                    ! [ Cmd.none ]

        ReceiveNewState response ->
            case JD.decodeValue Game.decoder response of
                Ok gameData ->
                    if
                        Board.commitUnchanged model.game.board gameData.board
                            && not (Board.exchanged model.game.board gameData.board)
                    then
                        model ! [ Cmd.none ]
                    else
                        { model | game = gameData } ! [ Cmd.none ]

                Err error ->
                    Debug.log error ( model, Cmd.none )


joinChannel : String -> ( Socket.Socket Msg, Cmd (Socket.Msg Msg) )
joinChannel gameId =
    let
        joinPayload =
            JE.object [ ( "game_id", JE.string gameId ) ]

        phxSocket =
            Socket.init "ws://localhost:4000/socket/websocket"
                |> Socket.on ("new_state:" ++ gameId) "game_room:lobby" ReceiveNewState

        channel =
            Channel.init "game_room:lobby"
                |> Channel.onJoin ShowJoinedMessage
                |> Channel.withPayload joinPayload
    in
        Socket.join channel phxSocket


patchItems : String -> String -> JE.Value -> Pusher.Push Msg
patchItems event gameId reqBody =
    Pusher.init (event ++ ":" ++ gameId) "game_room:lobby"
        |> Pusher.withPayload reqBody
        |> Pusher.onOk PatchResponse


beforeSubmit : Game.Model -> Msg
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


subscriptions : Model -> Sub Msg
subscriptions model =
    Socket.listen model.phxSocket PhoenixMsg


view : Model -> Html Msg
view model =
    div [ class "flex flex-wrap flex-nowrap-l justify-center items-center" ]
        [ Item.restItems model.game.items
        , section [ class "w-40-l mh4-l mb3-l" ]
            [ div [ class "relative" ]
                [ Board.view (List.head model.game.choices) model.game.board BoardMsg
                , Game.viewChoiceFor (List.head model.game.choices) model.game |> map GameMsg
                ]
            , div [ class "flex flex-wrap justify-between mt2 mt4-ns" ]
                [ Item.myItems model.game.items ItemMsg
                ]
            ]
        , section [ class "flex justify-between flex-auto flex-none-l db-l mt3 mt0-l ml2-l" ]
            [ a
                [ class "f6 link db ba b--blue blue ph2 pv2 tc pointer hover-bg-light-blue hover-dark-blue"
                , onClick Exchange
                ]
                [ text "Exchange" ]
            , a
                [ class "f6 link db ba pv2 pa4-l near-white tc pointer flex-auto bg-dark-blue hover-bg-blue mv5-l"
                , onClick (beforeSubmit model.game)
                ]
                [ text "SUBMIT" ]
            , a
                [ class "dn f6 link ba ph2 pv2 near-white tc pointer"
                , onClick ResetGame
                ]
                [ text "Reset Game" ]
            , a
                [ class "f6 link db ba ph2 pv2 near-white dim pointer tc"
                , onClick BatchRecall
                ]
                [ text "Recall" ]
            ]
        ]
