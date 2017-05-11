defmodule AMath.Web.PageController do
  use AMath.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
