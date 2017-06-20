defmodule AMath.Game.Item do
  use Ecto.Schema
  alias AMath.Game

  schema "game_items" do
    field :game_id, :string
    embeds_one :items, Game.Data, on_replace: :update

    timestamps()
  end

end
