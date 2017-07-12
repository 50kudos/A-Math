module Main exposing (main)

import Html exposing (Html, map, div, a, text, section, input, label, small, span, p)
import Html.Events exposing (onClick)
import Html.Attributes exposing (class, defaultValue, type_, autofocus, for, id, readonly)
import Helper as H
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
import Draggable


type alias Flags =
    { gameId : String
    , host : String
    }


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
    , host : String
    , game : Game.Model
    , players : List Player
    , phxSocket : Socket.Socket Msg
    , phxPresences : Presence.PresenceState DeckPresence
    }


type alias Position =
    { x : Float, y : Float }


type Msg
    = GameMsg Game.Msg
    | ItemMsg Item.Msg
    | BoardMsg Board.Msg
    | PhoenixMsg (Socket.Msg Msg)
    | JoinedResponse JE.Value
    | ResetGame
    | Exchange
    | Pass
    | BatchRecall
    | EnqueueChoices (List ( String, Int, Int ))
    | Push
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
        , host = flags.host
        , game = Game.init
        , players = []
        , phxSocket = phxSocket
        , phxPresences = Dict.empty
        }
            ! [ Cmd.map PhoenixMsg phxCmd
              ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    if (not << List.isEmpty) model.game.choices then
        case msg of
            GameMsg _ ->
                normalUpdate msg model

            _ ->
                ( model, Cmd.none )
    else if model.game.endStatus == Game.PassingEnded || model.game.endStatus == Game.DeckEnded then
        ( model, Cmd.none )
    else if model.game.myTurn then
        normalUpdate msg model
    else
        case msg of
            JoinedResponse a ->
                normalUpdate msg model

            PhoenixMsg a ->
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
                    if Game.isDraging msg then
                        game.choices
                    else
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
            case JD.decodeValue Game.joinedDecoder response of
                Ok gameData ->
                    let
                        items =
                            model.game.items

                        items_ =
                            { items
                                | deckId = gameData.deck.deckId
                                , deckName = gameData.deck.deckName
                                , myItems = gameData.deck.myItems
                                , restItems = gameData.common.restItems
                            }

                        board =
                            model.game.board

                        board_ =
                            { board
                                | committedItems = gameData.common.boardItems
                            }

                        game =
                            model.game

                        game_ =
                            { game
                                | items = items_
                                , board = board_
                                , myTurn = gameData.common.myTurn
                                , exchangeable = gameData.common.exchangeable
                                , p1Stat = gameData.common.p1Stat
                                , p2Stat = gameData.common.p2Stat
                                , endStatus = gameData.common.endStatus
                            }
                    in
                        { model | game = game_ }
                            ! [ Cmd.none ]

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

        Pass ->
            let
                reqBody =
                    JE.list []

                passEvent =
                    "pass:" ++ model.game.items.deckId

                ( phxSocket, phxCmd ) =
                    Socket.push (patchItems passEvent model.gameId reqBody) model.phxSocket
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
            case JD.decodeValue Game.myStateDecoder response of
                Ok gameData ->
                    let
                        game =
                            model.game

                        items =
                            model.game.items

                        items_ =
                            { items
                                | deckId = gameData.deckId
                                , deckName = gameData.deckName
                                , myItems = gameData.myItems
                            }

                        newGame =
                            { game | items = items_ }
                    in
                        { model | game = newGame } ! [ Cmd.none ]

                Err error ->
                    Debug.log error ( model, Cmd.none )

        ReceiveNewCommonState response ->
            case JD.decodeValue Game.commonStateDecoder response of
                Ok commonGameData ->
                    let
                        game =
                            model.game

                        items =
                            model.game.items

                        items_ =
                            { items | restItems = commonGameData.restItems }

                        board =
                            model.game.board

                        board_ =
                            { board
                                | committedItems = commonGameData.boardItems
                                , stagingItems = []
                            }

                        new_game =
                            { game
                                | items = items_
                                , board = board_
                                , myTurn = commonGameData.myTurn
                                , exchangeable = commonGameData.exchangeable
                                , p1Stat = commonGameData.p1Stat
                                , p2Stat = commonGameData.p2Stat
                                , endStatus = commonGameData.endStatus
                            }
                    in
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
                            Dict.keys newPresenceState |> List.map Player
                    in
                        ( { model | phxPresences = newPresenceState, players = players }, Cmd.none )

                Err error ->
                    Debug.log error ( model, Cmd.none )


type alias DeckPresence =
    { onlineAt : String
    }


type alias Player =
    { name : String }


deckPresenceDecoder : JD.Decoder DeckPresence
deckPresenceDecoder =
    JD.map DeckPresence
        (JD.field "online_at" JD.string)


joinChannel : Flags -> ( Socket.Socket Msg, Cmd (Socket.Msg Msg) )
joinChannel { gameId, host } =
    let
        joinPayload =
            JE.object [ ( "game_id", JE.string gameId ) ]

        phxSocket =
            Socket.init ("ws://" ++ host ++ "/socket/websocket")
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
    Sub.batch
        [ Socket.listen model.phxSocket PhoenixMsg
        , Draggable.subscriptions Game.DragMsg model.game.drag |> Sub.map GameMsg
        ]


viewCopyUrl : String -> String -> Html msg
viewCopyUrl host gameId =
    div [ class "fixed z-9999 h-100 w-100 flex items-center justify-center light-gray bg-white-70" ]
        [ div [ class "w-90 w-50-l" ]
            [ label [ for "game_url", class "f4 db mb2 black" ] [ text "Game room link" ]
            , small [ class "f6 black-80 db mb2" ] [ text "To start the game, copy and send the link below to your friend!" ]
            , input
                [ type_ "url"
                , readonly True
                , autofocus True
                , id "game_url"
                , class "pointer input-reset ba b--black-20 pa2 mb2 db w-100"
                , defaultValue ("http://" ++ host ++ "/game/" ++ gameId)
                ]
                []
            , small [ class "f7 black-80 db mb2" ] [ text "Your friend have not been joined the game or they are disconnected." ]
            ]
        ]


waiting : a -> List Player -> Maybe a
waiting a players =
    if 0 < (List.length players) && (List.length players) < 2 then
        Just a
    else
        Nothing


exchangeOrPass : Bool -> Bool -> Msg -> Msg -> Html Msg
exchangeOrPass myTurn exchangeable exchangeMsg passMsg =
    let
        ( msg, btnText ) =
            if exchangeable then
                ( exchangeMsg, "Exchange" )
            else
                ( passMsg, "Pass" )
    in
        a
            [ class (H.exchangeButtonClass myTurn)
            , onClick msg
            ]
            [ text btnText ]


viewStat : Game.Model -> Game.EndStatus -> Html msg
viewStat game endStatus =
    let
        winOrLose : String -> String -> String -> Html msg
        winOrLose myDeckName playerDeckname winnerDeckName =
            let
                ( text_, cssClass ) =
                    if myDeckName == winnerDeckName then
                        if myDeckName == playerDeckname then
                            ( "YOU WIN!", "bg-blue near-white" )
                        else
                            ( "DUDE", "bg-near-white mid-gray" )
                    else if myDeckName == playerDeckname then
                        ( "YOU LOSE!", "bg-blue near-white" )
                    else
                        ( "DUDE", "bg-near-white mid-gray" )
            in
                span [ class <| cssClass ++ " f6 pa2 tc br2 br--bottom" ]
                    [ text text_ ]

        passingEndDetail : Int -> Maybe Int -> List (Html msg)
        passingEndDetail point deckPoint =
            [ p [ class "ma0 fw1 f7 blue" ]
                [ text <| "Point = " ++ (toString point) ]
            , p [ class "ma0 fw1 f7 blue" ]
                [ text <| "Deck -" ++ (toString <| Maybe.withDefault 0 deckPoint) ]
            , p [ class "ma0 pv3 f4 near-white h-100 flex items-center justify-center" ]
                [ text (toString <| point - Maybe.withDefault 0 deckPoint) ]
            ]

        deckEndDetail : Int -> Maybe Int -> List (Html msg)
        deckEndDetail point opDeckPoint =
            [ p [ class "ma0 fw1 f7 blue" ]
                [ text <| "Point = " ++ (toString point) ]
            , p [ class "ma0 fw1 f7 blue" ]
                [ text <| "Bonus +" ++ (toString <| Maybe.withDefault 0 opDeckPoint) ]
            , p [ class "ma0 pv3 f4 near-white h-100 flex items-center justify-center" ]
                [ text (toString <| point + Maybe.withDefault 0 opDeckPoint) ]
            ]

        endingDetail : Game.EndStatus -> { x | point : Int, deckPoint : Maybe Int } -> { y | point : Int, deckPoint : Maybe Int } -> Html msg
        endingDetail endStatus aStat bStat =
            case endStatus of
                Game.PassingEnded ->
                    div [ class "pa2" ] (passingEndDetail aStat.point aStat.deckPoint)

                Game.DeckEnded ->
                    div [ class "pa2" ] (deckEndDetail aStat.point bStat.deckPoint)

                a ->
                    Debug.log "Unexpected game ending status" text (toString a)
    in
        section []
            [ div [ class "flex flex-column w4 ba b--gray br2 mv4" ] <|
                [ span [ class "tc f6 pa1 bg-near-white mid-gray br2 br--top" ]
                    [ text game.p1Stat.deckName ]
                , endingDetail game.endStatus game.p1Stat game.p2Stat
                , winOrLose game.items.deckName game.p1Stat.deckName (winner game)
                ]
            , div [ class "flex flex-column w4 ba b--gray br2 mv4" ] <|
                [ span [ class "tc f6 pa1 bg-near-white mid-gray br2 br--top" ]
                    [ text game.p2Stat.deckName ]
                , endingDetail game.endStatus game.p2Stat game.p1Stat
                , winOrLose game.items.deckName game.p2Stat.deckName (winner game)
                ]
            ]


turnStatus : Bool -> Item.Model -> String -> Html Msg
turnStatus myTurn myDeck deckName =
    if myTurn then
        if myDeck.deckName == deckName then
            span [ class "f6 pa2 tc bg-blue near-white br2 br--bottom" ]
                [ text "Your turn" ]
        else
            span [ class "f6 pa2 tc bg-near-white mid-gray br2 br--bottom" ]
                [ text "DUDE" ]
    else if myDeck.deckName == deckName then
        span [ class "f6 pa2 tc bg-near-white mid-gray br2 br--bottom" ]
            [ text "YOU" ]
    else
        span [ class "f7 pv2 ph1 tc bg-blue near-white br2 br--bottom" ]
            [ text "Dude is thinking .." ]


viewPlaying : Game.Model -> Html Msg
viewPlaying game =
    section []
        [ section [ class "mb5-l" ]
            [ div [ class "flex flex-column h4 ba b--gray br2 mv4" ]
                [ span [ class "f6 pv2 bg-near-white mid-gray flex items-center justify-center br2 br--top" ]
                    [ text game.p1Stat.deckName ]
                , p [ class "ma0 f4 near-white h-100 flex items-center justify-center" ]
                    [ text (toString game.p1Stat.point) ]
                , turnStatus game.myTurn game.items game.p1Stat.deckName
                ]
            , div [ class "flex flex-column h4 ba b--gray br2 mv4" ]
                [ span [ class "f6 pv2 bg-near-white mid-gray flex items-center justify-center br2 br--top" ]
                    [ text game.p2Stat.deckName ]
                , p [ class "ma0 f4 near-white h-100 flex items-center justify-center" ]
                    [ text (toString game.p2Stat.point) ]
                , turnStatus game.myTurn game.items game.p2Stat.deckName
                ]
            ]
        , section []
            [ exchangeOrPass game.myTurn game.exchangeable Exchange Pass
            , a
                [ class (H.submitButtonClass game.myTurn)
                , onClick (beforeSubmit game)
                ]
                [ text "SUBMIT" ]
            , a
                [ class (H.recallButtonClass game.myTurn)
                , onClick BatchRecall
                ]
                [ text "Recall" ]
            ]
        ]


winner : Game.Model -> String
winner game =
    let
        p1Deck =
            Maybe.withDefault 0 game.p1Stat.deckPoint

        p2Deck =
            Maybe.withDefault 0 game.p2Stat.deckPoint
    in
        if (game.p1Stat.point - p1Deck) > (game.p2Stat.point - p2Deck) then
            game.p1Stat.deckName
        else
            game.p2Stat.deckName


viewRightPanel : Game.Model -> Html Msg
viewRightPanel game =
    case game.endStatus of
        Game.Running ->
            viewPlaying game

        Game.PassingEnded ->
            viewStat game Game.PassingEnded

        Game.DeckEnded ->
            viewStat game Game.DeckEnded


view : Model -> Html Msg
view model =
    div [ class "flex flex-wrap flex-nowrap-l justify-center items-center items-stretch-m" ]
        [ waiting (viewCopyUrl model.host model.gameId) model.players |> Maybe.withDefault (text "")
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
        , section [ class "flex justify-between flex-auto flex-none-l self-end db-l w4 pa2 mt3 mt0-l ml2-l mb5-l pb3-l" ]
            [ viewRightPanel model.game
            ]
        ]
