defmodule AMath.Web.ItemView do
  use AMath.Web, :view
  alias AMath.Web.ItemView
  alias AMath.Web.Endpoint
  alias AMath.Game

  import IEx
  def render("index.json", %{items: items}) do
    %{data: render_many(items, ItemView, "item.json")}
  end

  def render("show.json", %{state: data, deck: deck}) do
    %{
      deckId: Phoenix.Token.sign(Endpoint, "The north remembers", deck.id),
      myItems: render_many(deck.items, ItemView, "my_item.json")
    }
  end

  def render("common_show.json", %{state: data, deck: deck}) do
    %{
      myTurn: Game.handle_turn(data.turn_queue, deck.id),
      boardItems: render_many(data.boardItems, ItemView, "board_item.json"),
      restItems: render_many(Game.get_rest_for(data, deck.id), ItemView, "item.json"),
      p1Point: data.p1_deck.point,
      p2Point: data.p2_deck.point
    }
  end
  
  def render("join.json", %{state: data, deck: deck}) do
    Map.merge(
      render("show.json", %{state: data, deck: deck}),
      render("common_show.json", %{state: data, deck: deck})
    )
  end

  def render("item.json", %{item: item}) do
    %{item: item.item, ea: item.ea, point: item.point}
  end
  
  def render("my_item.json", %{item: item}) do
    %{item: item.item, point: item.point}
  end
  
  def render("board_item.json", %{item: item}) do
    %{item: item.item, i: item.i, j: item.j, point: item.point, value: item.value}
  end

end
