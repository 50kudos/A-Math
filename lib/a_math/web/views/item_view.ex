defmodule AMath.Web.ItemView do
  use AMath.Web, :view
  alias AMath.Web.ItemView

  def render("index.json", %{items: items}) do
    %{data: render_many(items, ItemView, "item.json")}
  end

  def render("show.json", %{state: data}) do
    %{
      boardItems: render_many(data["boardItems"], ItemView, "board_item.json"),
      myItems: render_many(data["myItems"], ItemView, "item.json"),
      restItems: render_many(data["restItems"], ItemView, "item.json")
    }
  end

  def render("item.json", %{item: item}) do
    %{item: item["item"], ea: item["ea"], point: item["point"]}
  end
  
  def render("board_item.json", %{item: item}) do
    %{item: item["item"], i: item["i"], j: item["j"]}
  end
end
