defmodule AMath.Web.ItemController do
  use AMath.Web, :controller

  alias AMath.Game
  alias AMath.Game.Item

  action_fallback AMath.Web.FallbackController

  def index(conn, _params) do
    items = Game.list_items()
    render(conn, "index.json", items: items)
  end

  def create(conn, %{"item" => item_params}) do
    with {:ok, %Item{} = item} <- Game.create_item(item_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", item_path(conn, :show, item))
      |> render("show.json", item: item)
    end
  end

  def show(conn, %{"id" => id}) do
    state = Game.get_item!(id)
    render(conn, "show.json", state: state.items)
  end

  def update(conn, %{"id" => id, "items" => item_params, "patchType" => type}) do
    item = Game.get_item!(id)

    with {:ok, %Item{} = state} <- update_data(type, item, item_params) do
      render(conn, "show.json", state: state.items)
    end
  end

  def delete(conn, %{"id" => id}) do
    item = Game.get_item!(id)
    with {:ok, %Item{}} <- Game.delete_item(item) do
      send_resp(conn, :no_content, "")
    end
  end
  
  defp update_data("commit", item, item_params) do
    Game.update_commit(item, item_params)
  end
  defp update_data("exchange", item, item_params) do
    Game.update_exchange(item, item_params)
  end
  defp update_data("reset", item, _item_params) do
    Game.create_item(item)
  end
end
