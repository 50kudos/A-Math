defmodule AMath.Web.ItemController do
  use AMath.Web, :controller

  alias AMath.Game
  alias AMath.Game.Item

  action_fallback AMath.Web.FallbackController

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
  
  defp update_data("commit", item, item_params) do
    Game.update_commit(item, item_params)
  end
  defp update_data("exchange", item, item_params) do
    Game.update_exchange(item, item_params)
  end
  defp update_data("reset", item, _item_params) do
    Game.reset_game(item)
  end
end
