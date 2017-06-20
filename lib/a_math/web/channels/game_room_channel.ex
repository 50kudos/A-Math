defmodule AMath.Web.GameRoomChannel do
  use AMath.Web, :channel
  alias AMath.Web.PlayerPresence
  alias AMath.Game
  alias AMath.Game.Item
  alias AMath.Game.Data
  alias AMath.Web.ItemView
  import IEx

  def join("game_room:" <> game_id, _payload, socket) do
    if authorized?(game_id) do
      game = Game.get_item!(game_id)
      items = game.items
      
      case get_deck_id_by(socket, items) do
        {:ok, deck} ->
          response = ItemView.render("show.json", %{state: items, deck: deck})
          send(self(), :after_join)
          {:ok, response, assign(socket, :deck_id, deck.id)}
        
        {:error, _reason} ->
          {:error, %{reason: "unauthorized"}}
      end
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("commit:" <> deck_id, %{"items" => item_params}, socket) do
    "game_room:" <> game_id = socket.topic
    game = Game.get_item!(game_id)
    deck = Game.get_deck(Data.to_map(game), deck_id)

    with {:ok, %Item{} = new_game} <- Game.update_commit(game, item_params, deck.key) do
      new_deck = Game.get_deck(Data.to_map(new_game), deck_id)
      response = ItemView.render("show.json", %{state: new_game.items, deck: new_deck})
      push socket, "new_state", response

      response = ItemView.render("common_show.json", %{state: new_game.items})
      broadcast_from socket, "common_state", response

      {:noreply, socket}
    else
      {:error, _} -> {:noreply, socket}
    end
  end
  def handle_in("exchange:" <> deck_id, %{"items" => item_params}, socket) do
    "game_room:" <> game_id = socket.topic
    game = Game.get_item!(game_id)
    deck = Game.get_deck(Data.to_map(game), deck_id)

    with {:ok, %Item{} = new_game} <- Game.update_exchange(game, item_params, deck.key) do
      new_deck = Game.get_deck(Data.to_map(new_game), deck_id)
      response = ItemView.render("show.json", %{state: new_game.items, deck: new_deck})
      push socket, "new_state", response
      
      response = ItemView.render("common_show.json", %{state: new_game.items})
      broadcast_from socket, "common_state", response

      {:noreply, socket}
    else
      {:error, _} -> {:noreply, socket}
    end
  end
  def handle_in("reset:" <> deck_id, _payload, socket) do
    "game_room:" <> game_id = socket.topic

    with {:ok, %Item{} = new_game} <- Game.reset_game(game_id) do
      new_deck = Game.get_deck(Data.to_map(new_game), deck_id)
      response = ItemView.render("show.json", %{state: new_game.items, deck: new_deck})
      push socket, "new_state", response

      response = ItemView.render("common_show.json", %{state: new_game.items})
      broadcast_from socket, "common_state", response

      {:noreply, socket}
    else
      {:error, _} -> {:noreply, socket}
    end
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (game_room:lobby).
  def handle_in("shout", payload, socket) do
    broadcast socket, "shout", payload
    {:noreply, socket}
  end
  
  def handle_in(_, _, socket) do
    {:noreply, socket}
  end
  
  def handle_info(:after_join, socket) do
    {:ok, _} = PlayerPresence.track(socket, socket.assigns.deck_id, %{
      online_at: inspect(System.system_time(:seconds))
    })

    broadcast socket, "presence_state", PlayerPresence.list(socket)
    {:noreply, socket}
  end

  defp get_deck_id_by(socket, items) do
    case Map.keys PlayerPresence.list(socket) do
      [] ->
        {:ok, items.p1_deck}

      [deck] ->
        if deck == items.p1_deck.id do
          {:ok, items.p2_deck}
        else
          {:ok, items.p1_deck}
        end

      _ ->
        {:error, "Game room is full."}
    end
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
