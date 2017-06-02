module Game exposing (..)

import Item
import Http


type Msg
    = Fetch (Result Http.Error Item.Model)


update : Msg -> Item.Model -> Item.Model
update msg model =
    case msg of
        Fetch (Ok items) ->
            items

        Fetch (Err error) ->
            Debug.log (toString error) model


getItems : Cmd Msg
getItems =
    Http.send Fetch <|
        Http.get "http://localhost:4000/api/items/3" Item.decoder
