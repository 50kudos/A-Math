defmodule AMath.Game.Data do
  use Ecto.Schema

  import Ecto.Changeset, warn: false
  alias AMath.Game.Item
  alias AMath.Game.Data.Deck

  @primary_key false

  embedded_schema do
    field :turn_queue, {:array, :string}, default: []
    field :passed, :integer, default: 0

    embeds_one :p1_deck, Deck, on_replace: :update
    embeds_one :p2_deck, Deck, on_replace: :update

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
      field :value, :string
    end
  end

  def changeset(%Item{} = item, attrs) do
    item
    |> cast(attrs, [])
    |> cast_embed(:items, with: &items_changeset/2)
  end

  def items_changeset(struct, attrs) do
    struct
    |> cast(attrs, [:turn_queue, :passed])
    |> cast_embed(:p1_deck, with: &Deck.changeset/2)
    |> cast_embed(:p2_deck, with: &Deck.changeset/2)
    |> cast_embed(:restItems, with: &restItem_changeset/2)
    |> cast_embed(:boardItems, with: &boardItems_changeset/2)
  end

  def restItem_changeset(struct, attrs) do
    struct
    |> cast(attrs, [:item, :ea, :point])
  end

  def boardItems_changeset(struct, attrs) do
    struct
    |> cast(attrs, [:item, :i, :j, :point, :value])
  end

  def to_map(%{items: struct}) do
    %{items: Jason.encode!(struct) |> Jason.decode!(keys: :atoms!)}
  end

  def board_map(board_items) do
    map_fn = fn board_item ->
      %{
        i: (board_item["i"] || board_item.i),
        j: (board_item["j"] || board_item.j),
        item: (board_item["item"] || board_item.item),
        point: (board_item["point"] || board_item.point),
        value: (board_item["value"] || board_item.value)
      }
    end

    Enum.map(board_items, map_fn)
  end

  def expand_items(rest_items) do
    rest_items
    |> Enum.map(&List.duplicate(&1, &1.ea))
    |> List.flatten()
  end

  def compact_items(rand_items) do
    rand_items
    |> Enum.group_by(&(&1.item))
    |> Enum.map(fn {k,v} -> {k,Enum.count(v)} end)
  end
end
