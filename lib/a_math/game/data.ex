defmodule AMath.Game.Data do
  use Ecto.Schema
  
  import Ecto.Changeset, warn: false
  alias AMath.Game.Item

  @primary_key false

  embedded_schema do
    embeds_many :myItems, DeckItem, primary_key: false, on_replace: :delete do
      field :item, :string
      field :point, :integer
    end
    
    embeds_many :restItems, RestItem, primary_key: false, on_replace: :delete do
      field :item, :string
      field :ea, :integer
      field :point, :integer
    end

    embeds_many :boardItems, BoardItem, primary_key: false, on_replace: :delete do
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
    }
  end
  
  def board_map(board_items) do
    map_fn = fn board_item ->
      %{
        i: (board_item["i"] || board_item.i),
        j: (board_item["j"] || board_item.j),
        item: (board_item["item"] || board_item.item),
        point: (board_item["point"] || board_item.point)
      }
    end
    
    Enum.map(board_items, map_fn)
  end
  
  def expand_items(rest_items) do
    rest_items
    |> Enum.map(&List.duplicate(&1, &1.ea))
    |> List.flatten()
  end
end
