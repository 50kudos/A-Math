defmodule AMath.Game.Item do
  use Ecto.Schema

  schema "game_items" do
    field :items, :map

    timestamps()
  end
end
