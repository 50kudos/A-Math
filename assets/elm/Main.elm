module Main exposing (main)

import Html exposing (Html, map, div, a, text, section, input, label, small, span)
import Html.Events exposing (onClick)
import Html.Attributes exposing (class, defaultValue, type_, autofocus, for, id, readonly)
import Phoenix.Socket as Socket
import Phoenix.Channel as Channel
import Phoenix.Push as Pusher
import Phoenix.Presence as Presence
import Json.Encode as JE
import Json.Decode as JD
import Dict
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
    { gameId : String
    , game : Game.Model
    , players : List Player
    , phxSocket : Socket.Socket Msg
    , phxPresences : Presence.PresenceState DeckPresence
    }


type Msg
    = GameMsg Game.Msg
    | ItemMsg Item.Msg
    | BoardMsg Board.Msg
    | PhoenixMsg (Socket.Msg Msg)
    | JoinedResponse JE.Value
    | ResetGame
    | Exchange
    | BatchRecall
    | EnqueueChoices (List ( String, Int, Int ))
    | Push
    | PatchResponse JE.Value
    | ReceiveNewState JE.Value
    | ReceiveNewCommonState JE.Value
    | ReceivePresence JE.Value
    | ReceivePresenceDiff JE.Value


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        ( phxSocket, phxCmd ) =
            joinChannel flags
    in
        { gameId = flags.gameId
        , game = Game.init
        , players = []
        , phxSocket = phxSocket
        , phxPresences = Dict.empty
        }
            ! [ Cmd.map PhoenixMsg phxCmd
              ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    if model.game.myTurn then
        normalUpdate msg model
    else
        case msg of
            JoinedResponse a ->
                normalUpdate msg model

            PhoenixMsg a ->
                normalUpdate msg model

            PatchResponse a ->
                normalUpdate msg model

            ReceiveNewState a ->
                normalUpdate msg model

            ReceiveNewCommonState a ->
                normalUpdate msg model

            ReceivePresence a ->
                normalUpdate msg model

            ReceivePresenceDiff a ->
                normalUpdate msg model

            ItemMsg a ->
                normalUpdate msg model

            _ ->
                ( model, Cmd.none )


normalUpdate : Msg -> Model -> ( Model, Cmd Msg )
normalUpdate msg model =
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

        JoinedResponse response ->
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

                exchangeEvent =
                    "exchange:" ++ model.game.items.deckId

                ( phxSocket, phxCmd ) =
                    Socket.push (patchItems exchangeEvent model.gameId reqBody) model.phxSocket
            in
                ( { model | phxSocket = phxSocket }, Cmd.map PhoenixMsg phxCmd )

        Push ->
            let
                reqBody =
                    (Board.encoder model.game.board)

                commitEvent =
                    "commit:" ++ model.game.items.deckId

                ( phxSocket, phxCmd ) =
                    Socket.push (patchItems commitEvent model.gameId reqBody) model.phxSocket
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
            case JD.decodeValue Item.decoder response of
                Ok gameData ->
                    let
                        game =
                            model.game

                        newGame =
                            { game | items = gameData }
                    in
                        { model | game = newGame } ! [ Cmd.none ]

                Err error ->
                    Debug.log error ( model, Cmd.none )

        ReceiveNewCommonState response ->
            case JD.decodeValue Game.commonStateDecoder response of
                Ok gameData ->
                    let
                        game =
                            model.game

                        items =
                            model.game.items

                        new_game =
                            { game | board = gameData.board, myTurn = gameData.myTurn }
                    in
                        if
                            Board.commitUnchanged model.game.board gameData.board
                                && not (Board.exchanged model.game.board gameData.board)
                        then
                            model ! [ Cmd.none ]
                        else
                            { model | game = new_game } ! [ Cmd.none ]

                Err error ->
                    Debug.log error ( model, Cmd.none )

        ReceivePresence response ->
            case JD.decodeValue (Presence.presenceStateDecoder deckPresenceDecoder) response of
                Ok presenceState ->
                    let
                        newPresenceState =
                            model.phxPresences |> Presence.syncState presenceState
                    in
                        ( { model | phxPresences = newPresenceState }, Cmd.none )

                Err error ->
                    Debug.log error ( model, Cmd.none )

        ReceivePresenceDiff response ->
            case JD.decodeValue (Presence.presenceDiffDecoder deckPresenceDecoder) response of
                Ok presenceState ->
                    let
                        newPresenceState =
                            model.phxPresences |> Presence.syncDiff presenceState

                        players =
                            Dict.keys newPresenceState |> List.map (\k -> Player k 0)
                    in
                        ( { model | phxPresences = newPresenceState, players = players }, Cmd.none )

                Err error ->
                    Debug.log error ( model, Cmd.none )


type alias DeckPresence =
    { onlineAt : String
    }


type alias Player =
    { name : String
    , point : Int
    }


deckPresenceDecoder : JD.Decoder DeckPresence
deckPresenceDecoder =
    JD.map DeckPresence
        (JD.field "online_at" JD.string)


joinChannel : Flags -> ( Socket.Socket Msg, Cmd (Socket.Msg Msg) )
joinChannel { gameId } =
    let
        joinPayload =
            JE.object [ ( "game_id", JE.string gameId ) ]

        phxSocket =
            Socket.init "ws://localhost:4000/socket/websocket"
                |> Socket.withDebug
                |> Socket.on "new_state" ("game_room:" ++ gameId) ReceiveNewState
                |> Socket.on "common_state" ("game_room:" ++ gameId) ReceiveNewCommonState
                |> Socket.on "presence_state" ("game_room:" ++ gameId) ReceivePresence
                |> Socket.on "presence_diff" ("game_room:" ++ gameId) ReceivePresenceDiff

        channel =
            Channel.init ("game_room:" ++ gameId)
                |> Channel.onJoin JoinedResponse
                |> Channel.withPayload joinPayload
    in
        Socket.join channel phxSocket


patchItems : String -> String -> JE.Value -> Pusher.Push Msg
patchItems event gameId reqBody =
    Pusher.init event ("game_room:" ++ gameId)
        |> Pusher.withPayload reqBody



-- |> Pusher.onOk PatchResponse


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


viewCopyUrl : String -> Html msg
viewCopyUrl gameId =
    div [ class "fixed z-9999 h-100 w-100 flex items-center justify-center light-gray bg-black-70" ]
        [ div [ class "w-90 w-50-l" ]
            [ label [ for "game_url", class "f4 db mb2" ] [ text "Game room url" ]
            , input
                [ type_ "url"
                , readonly True
                , autofocus True
                , id "game_url"
                , class "pointer input-reset ba b--black-20 pa2 mb2 db w-100"
                , defaultValue ("http://localhost:4000/game/" ++ gameId)
                ]
                []
            , small [ class "f6 white-80 db mb2" ] [ text "To play the game, copy and send the url to your friend!" ]
            ]
        ]


waiting : a -> List Player -> Maybe a
waiting a players =
    if 0 < (List.length players) && (List.length players) < 2 then
        Just a
    else
        Nothing


view : Model -> Html Msg
view model =
    div [ class "flex flex-wrap flex-nowrap-l justify-center items-center items-stretch-m" ]
        [ waiting (viewCopyUrl model.gameId) model.players |> Maybe.withDefault (text "")
        , Item.restItems model.game.items
        , section [ class "w-40-l mh4-l mb3-l" ]
            [ div [ class "relative" ]
                [ Board.view (List.head model.game.choices) model.game.board BoardMsg
                , Game.viewChoiceFor (List.head model.game.choices) model.game |> map GameMsg
                ]
            , div [ class "flex flex-wrap justify-between mt2 mt4-ns" ]
                [ Item.myItems model.game.items ItemMsg
                ]
            ]
        , section [ class "flex justify-between flex-auto flex-none-l self-end db-l mt3 mt0-l ml2-l mb5-l pb3-l" ]
            [ section []
                [ span [ class "blue" ]
                    [ text
                        (if model.game.myTurn then
                            "Playing .."
                         else
                            "Waiting .."
                        )
                    ]
                ]
            , a
                [ class "f6 link db ba b--blue blue ph2 pv2 tc pointer hover-bg-light-blue hover-dark-blue"
                , onClick Exchange
                ]
                [ text "Exchange" ]
            , a
                [ class "f6 link db ba pv2 pa4-l near-white tc pointer bg-dark-blue hover-bg-blue flex-auto"
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
