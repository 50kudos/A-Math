defmodule AMath.Game.Data.Deck do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :point, :integer

    embeds_many :items, Item, primary_key: false, on_replace: :delete do
      field :item, :string
      field :point, :integer
    end
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, [:point])
    |> cast_embed(:items, with: &items_changeset/2)
  end
  
  defp items_changeset(struct, attrs) do
    struct
    |> cast(attrs, [:item, :point])
  end
end
