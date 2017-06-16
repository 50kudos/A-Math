module Main exposing (main)

import Html exposing (Html, map)
import Phoenix.Socket
import Phoenix.Channel
import Phoenix.Push
import Json.Encode as JE
import Json.Decode as JD
import Game


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { game : Game.Model
    , phxSocket : Phoenix.Socket.Socket Msg
    }


type Msg
    = GameMsg Game.Msg
    | PhoenixMsg (Phoenix.Socket.Msg Msg)
    | ShowJoinedMessage JE.Value


init : ( Model, Cmd Msg )
init =
    let
        ( phxSocket, phxCmd ) =
            joinChannel
    in
        { game = Game.init, phxSocket = phxSocket }
            ! [ Cmd.map PhoenixMsg phxCmd
              ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GameMsg msg ->
            let
                ( game, gameCmd ) =
                    Game.update msg model.game
            in
                { model | game = game } ! [ Cmd.map GameMsg gameCmd ]

        PhoenixMsg msg ->
            let
                ( phxSocket, phxCmd ) =
                    Phoenix.Socket.update msg model.phxSocket
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


joinChannel : ( Phoenix.Socket.Socket Msg, Cmd (Phoenix.Socket.Msg Msg) )
joinChannel =
    let
        phxSocket =
            Phoenix.Socket.init "ws://localhost:4000/socket/websocket"

        channel =
            Phoenix.Channel.init "game_room:lobby"
                |> Phoenix.Channel.onJoin ShowJoinedMessage
    in
        Phoenix.Socket.join channel phxSocket


subscriptions : Model -> Sub Msg
subscriptions model =
    Phoenix.Socket.listen model.phxSocket PhoenixMsg


view : Model -> Html Msg
view model =
    Game.view model.game |> map GameMsg
