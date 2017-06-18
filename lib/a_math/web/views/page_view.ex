defmodule AMath.Web.PageView do
  use AMath.Web, :view
  
  def create_game(conn) do
    page_path(conn, :create)
  end
end
