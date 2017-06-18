defmodule AMath.Game.Item do
  use Ecto.Schema
  
  schema "game_items" do
    field :game_id, :string
    embeds_one :items, AMath.Game.Data, on_replace: :delete
    
    timestamps()
  end
end
