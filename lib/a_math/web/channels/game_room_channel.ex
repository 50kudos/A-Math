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
      {:ok, game} <- Game.enqueue_deck(game, &(Enum.uniq(&1 ++ [deck.id])))
    do
      send(self(), :after_join)

      {:ok,
        ItemView.render("join.json", %{state: game.items, deck: deck}),
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
  
  intercept ["presence_diff", "common_state"]
  def handle_out("presence_diff", msg, socket) do
    sync_deck_presence(socket)
    |> push("presence_diff", msg)
    
    {:noreply, socket}
  end
  def handle_out("common_state", resp, socket) do
    turn_id = List.first(resp.myTurn)
    push socket, "common_state", %{resp | myTurn: turn_id == socket.assigns.deck_id }

    {:noreply, socket}
  end
  
  def handle_info(:after_join, socket) do
    push socket, "presence_state", PlayerPresence.list(socket)

    {:ok, _} = PlayerPresence.track(socket, socket.assigns.deck_id, %{
      online_at: inspect(System.system_time(:seconds))
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
    deck = get_deck(game, verify_deck(deck_id))
    
    with {:ok, %Item{} = new_game} <- func.(game, item_params, deck.key),
      {:ok, new_game} <- Game.rotate_turn(new_game),
      %{id: _, key: _, items: _} = new_deck <- get_deck(new_game, deck.id)
    do
      {:noreply,
        socket
        |> push_new_state(new_deck, new_game.items)
        |> broadcast_common_state(new_game.items)
      }
    else
      _ -> {:noreply, socket}
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
    broadcast(socket, "common_state", common_state)
    socket
  end
  
  defp verify_deck(deck_id) do
    {:ok, id} = Phoenix.Token.verify(AMath.Web.Endpoint, "The north remembers", deck_id)
    id
  end
  
  defp sync_deck_presence(socket) do
    game = get_game(socket)

    case game.items.turn_queue do
      [_p1,_p2] ->
        socket
      _ ->
        game
        |> Game.enqueue_deck(fn _ -> sorted_presences(socket) end)
        socket
    end
  end
  
  def sorted_presences(socket) do
    PlayerPresence.list(socket)
      |> Enum.sort(fn ({_k0, %{metas: list0}},{_k1, %{metas: list1}}) ->
          (Enum.sort(Enum.map list0, &(&1.online_at)) |> List.first()) <
          (Enum.sort(Enum.map list1, &(&1.online_at)) |> List.first())
        end)
      |> Enum.map(fn {k,_} -> k end)
  end

  defp authorized?(_payload) do
    true
  end
end
