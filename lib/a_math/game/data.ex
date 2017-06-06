defmodule AMath.Game.Data do
  use Ecto.Schema
  
  import Ecto.Changeset, warn: false
  alias AMath.Game.Item

  @primary_key {:id, :binary_id, autogenerate: true}
  
  embedded_schema do
    embeds_many :myItems, DeckItem, primary_key: @primary_key do
      field :item, :string
      field :point, :integer
    end
    
    embeds_many :restItems, RestItem, primary_key: @primary_key do
      field :item, :string
      field :ea, :integer
      field :point, :integer
    end
    
    embeds_many :boardItems, BoardItem, primary_key: @primary_key do
      field :item, :string
      field :i, :integer
      field :j, :integer
      field :point, :integer
    end
  end
  
  def changeset(%Item{} = item, attrs) do
    item
    |> cast(attrs, [])
    |> cast_embed(:items, with: &items_changeset/2)
  end
  
  def items_changeset(struct, attrs) do
    struct
    |> cast(attrs, [])
    |> cast_embed(:myItems, with: &myItems_changeset/2)
    |> cast_embed(:restItems, with: &restItem_changeset/2)
    |> cast_embed(:boardItems, with: &boardItems_changeset/2)
  end
  
  def myItems_changeset(struct, attrs) do
    struct
    |> cast(attrs, [:item, :point])
  end
  
  def restItem_changeset(struct, attrs) do
    struct
    |> cast(attrs, [:item, :ea, :point])
  end
  
  def boardItems_changeset(struct, attrs) do
    struct
    |> cast(attrs, [:item, :i, :j, :point])
  end

  def to_map(%__MODULE_{items: struct}) do
    %{items: struct
      |> Map.from_struct()
      |> Map.take([:boardItems, :myItems, :restItems])
      |> Map.new(fn {k,list} -> {k, Enum.map(list, &Map.from_struct/1)} end)
      |> Map.put(:id, struct.id)
    }
  end
end
