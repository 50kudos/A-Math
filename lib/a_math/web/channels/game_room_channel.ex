defmodule AMath.Web.GameRoomChannel do
  use AMath.Web, :channel
  alias AMath.Web.ItemView
  alias AMath.Web.PlayerPresence
  alias AMath.Game
  alias AMath.Game.{Item, Data}

  import IEx

  def join("game_room:" <> game_id, _payload, socket) do
    with true <- authorized?(game_id),
      %Item{} = game <- Game.get_item!(game_id),
      {:ok, deck} <- get_available_deck(socket, game.items),
      {:ok, %Item{} = game} <- Game.enqueue_deck(game, deck.id)
    do
      send(self(), {:after_join, game.items.turn_queue})
      {:ok,
        ItemView.render("show.json", %{state: game.items, deck: deck}),
        assign(socket, :deck_id, deck.id)}
    else
      _ -> {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("commit:" <> deck_id, %{"items" => item_params}, socket) do
    update_game(socket, item_params, deck_id, &Game.update_commit/3)
  end
  def handle_in("exchange:" <> deck_id, %{"items" => item_params}, socket) do
    update_game(socket, item_params, deck_id, &Game.update_exchange/3)
  end
  def handle_in(_, _, socket), do: {:noreply, socket}
  
  intercept ["presence_diff"]
  def handle_out("presence_diff", msg, socket) do
    push socket, "presence_diff", msg
    {:noreply, socket}
  end
  
  def handle_info({:after_join, turn}, socket) do
    push socket, "presence_state", PlayerPresence.list(socket)

    {:ok, _} = PlayerPresence.track(socket, socket.assigns.deck_id, %{
      online_at: inspect(System.system_time(:seconds)),
      my_turn: socket.assigns.deck_id == List.last(turn)
    })

    {:noreply, socket}
  end
  
  defp get_available_deck(socket, items) do
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

  def update_game(socket, item_params, deck_id, func) when is_function(func, 3) do
    game = get_game(socket)
    deck = get_deck(game, deck_id)
    
    with {:ok, %Item{} = new_game} <- func.(game, item_params, deck.key),
      %{id: _, key: _, items: _} = new_deck <- get_deck(new_game, deck_id)
    do
      socket
      |> push_new_state(new_deck, new_game.items)
      |> broadcast_common_state(new_game.items)

      {:noreply, socket}
    else
      {:error, _} -> {:noreply, socket}
    end
  end
  
  defp get_game(%{topic: "game_room:" <> game_id}), do: Game.get_item!(game_id)

  defp get_deck(game, deck_id), do: Game.get_deck(Data.to_map(game), deck_id)
  
  defp push_new_state(socket, deck, items) do
    new_state = ItemView.render("show.json", %{state: items, deck: deck})
    push(socket, "new_state", new_state)
    socket
  end
  
  defp broadcast_common_state(socket, items) do
    common_state = ItemView.render("common_show.json", %{state: items})
    broadcast_from(socket, "common_state", common_state)
    socket
  end

  defp authorized?(_payload) do
    true
  end
end
