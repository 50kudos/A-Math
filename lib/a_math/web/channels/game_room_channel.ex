defmodule AMath.Web.GameRoomChannel do
  use AMath.Web, :channel
  alias AMath.Web.PlayerPresence
  alias AMath.Game
  alias AMath.Game.Item
  import IEx
  # t :: %Phoenix.Socket{
  #   assigns: %{},
  #   channel: atom,
  #   channel_pid: pid,
  #   endpoint: atom,
  #   handler: atom,
  #   id: nil,
  #   joined: boolean,
  #   pubsub_server: atom,
  #   ref: term,
  #   serializer: atom,
  #   topic: String.t,
  #   transport: atom,
  #   transport_name: atom,
  #   transport_pid: pid
  # }

  def join("game_room:lobby", %{"game_id" => game_id}, socket) do
    if authorized?(game_id) do
      game = Game.get_item!(game_id)
      response = AMath.Web.ItemView.render("show.json", %{state: game.items})

      {:ok, response, assign(socket, :user_id, 13)}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("reset_game:" <> game_id, %{"items" => item_params, "patchType" => "commit"}, socket) do
    item = Game.get_item!(game_id)

    with {:ok, %Item{} = game} <- Game.update_commit(item, item_params) do
      response = AMath.Web.ItemView.render("show.json", %{state: game.items})

      {:reply, {:ok, response}, socket}
    else
      {:error, _} -> {:noreply, socket}
    end
  end
  def handle_in("reset_game:" <> game_id, %{"items" => item_params, "patchType" => "exchange"}, socket) do
    item = Game.get_item!(game_id)

    with {:ok, %Item{} = game} <- Game.update_exchange(item, item_params) do
      response = AMath.Web.ItemView.render("show.json", %{state: game.items})

      {:reply, {:ok, response}, socket}
    else
      {:error, _} -> {:noreply, socket}
    end
  end
  def handle_in("reset_game:" <> game_id, %{"items" => items, "patchType" => "reset"}, socket) do
    with {:ok, %Item{} = game} <- Game.reset_game(game_id) do
      response = AMath.Web.ItemView.render("show.json", %{state: game.items})

      {:reply, {:ok, response}, socket}
    else
      {:error, _} -> {:noreply, socket}
    end
  end
  def handle_in(_, _, socket) do
    {:noreply, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (game_room:lobby).
  def handle_in("shout", payload, socket) do
    broadcast socket, "shout", payload
    {:noreply, socket}
  end
  
  def handle_info(:after_join, socket) do
    push socket, "presence_state", PlayerPresence.list(socket)
    {:ok, _} = PlayerPresence.track(socket, socket.assigns.user_id, %{
      online_at: inspect(System.system_time(:seconds))
    })
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
