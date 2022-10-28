defmodule AMath.Web.PageView do
  use AMath.Web, :view

  def create_game(conn) do
    Routes.page_path(conn, :create)
  end
end
