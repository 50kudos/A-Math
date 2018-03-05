defmodule AMath.Web.PageController do
  use AMath.Web, :controller
  alias AMath.Game
  alias AMath.Game.Item

  action_fallback(AMath.Web.FallbackController)

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def show(conn, %{"id" => game_id}) do
    conn
    |> render("game_room.html", game_id: game_id, host: hostname())
  end

  def create(conn, _) do
    with {:ok, %Item{} = item} <- Game.create_item() do
      conn
      |> redirect(to: page_path(conn, :show, item.game_id))
    end
  end

  def rules(conn, _) do
    render(conn, "rules.html")
  end

  defp hostname() do
    :a_math
    |> Application.get_env(AMath.Web.Endpoint)
    |> Kernel.get_in([:url, :host])
  end
end
