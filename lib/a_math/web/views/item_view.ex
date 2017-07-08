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
      deckName: deck_name(deck.id),
      myItems: render_many(deck.items, ItemView, "my_item.json")
    }
  end

  def render("common_show.json", %{state: data, deck: deck}) do
    %{
      myTurn: Game.handle_turn(data.turn_queue, deck.id),
      exchangeable: Game.any_rest?(data),
      boardItems: render_many(data.boardItems, ItemView, "board_item.json"),
      restItems: render_many(Game.get_rest_for(data, deck.id), ItemView, "item.json"),
      p1Stat: player_stat(:p1Stat, data),
      p2Stat: player_stat(:p2Stat, data),
      gameEnded: Game.ended?(data)
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

  defp deck_name(deck_id) when is_binary(deck_id) do
    String.split(deck_id, "-")
    |> List.last
    |> Base.encode64(padding: false)
    |> binary_part(0, 8)
  end
  
  defp player_stat(:p1Stat, data) do
    p1_stat = %{deckName: deck_name(data.p1_deck.id), point: data.p1_deck.point}

    if Game.ended?(data) do
      p1_stat = Map.merge(p1_stat, %{deckPoint: items_point(data.p1_deck.items)})
    end
    p1_stat
  end
  defp player_stat(:p2Stat, data) do
    p2_stat = %{deckName: deck_name(data.p2_deck.id), point: data.p2_deck.point}

    if Game.ended?(data) do
      p2_stat = Map.merge(p2_stat, %{deckPoint: items_point(data.p2_deck.items)})
    end
    p2_stat
  end
  
  defp items_point(items) do
    Enum.reduce(items, 0, fn (item,acc) -> item.point + acc end)
  end
end
