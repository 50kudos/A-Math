module Main exposing (main)

import Html exposing (Html, map)
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
    { game : Game.Model }


type Msg
    = GameMsg Game.Msg


init : ( Model, Cmd Msg )
init =
    Model (Game.init)
        ! [ Game.getItems |> Cmd.map GameMsg
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


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


view : Model -> Html Msg
view model =
    Game.view model.game |> map GameMsg
