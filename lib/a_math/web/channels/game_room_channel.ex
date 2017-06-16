defmodule AMath.Web.GameRoomChannel do
  use AMath.Web, :channel
  alias AMath.Web.PlayerPresence

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

  def join("game_room:lobby", payload, socket) do
    if authorized?(payload) do
      send(self(), :after_join)
      
      response =
        AMath.Web.ItemView.render("show.json", %{state: AMath.Game.get_item!(10).items})

      {:ok, response, assign(socket, :user_id, 13)}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
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
