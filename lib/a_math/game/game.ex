defmodule AMath.Game do
  @moduledoc """
  The boundary for the Game system.
  """
  import IEx
  import Ecto.{Query, Changeset}, warn: false
  alias AMath.Repo

  alias AMath.Game.Item
  alias AMath.Game.Data

  @doc """
  Returns the list of items.

  ## Examples

      iex> list_items()
      [%Item{}, ...]

  """
  def list_items do
    Repo.all(Item)
  end

  @doc """
  Gets a single item.

  Raises `Ecto.NoResultsError` if the Item does not exist.

  ## Examples

      iex> get_item!(123)
      %Item{}

      iex> get_item!(456)
      ** (Ecto.NoResultsError)

  """
  def get_item!(id) do
    Repo.get!(Item, id)
  end

  @doc """
  Creates a item.

  ## Examples

      iex> create_item(%{field: value})
      {:ok, %Item{}}

      iex> create_item(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_item(attrs \\ %{}) do
    %Item{}
    |> item_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a item.

  ## Examples

      iex> update_item(item, %{field: new_value})
      {:ok, %Item{}}

      iex> update_item(item, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_data(%Item{} = prev_data, attrs) do
    game = Data.to_map(prev_data)

    with {:ok, new_data, committed_count} <- change_board(game, attrs),
      {:ok, new_data, ramdom_items} <- change_rest(new_data, committed_count),
      {:ok, new_data} <- change_mine(new_data, attrs, ramdom_items) do
      
      prev_data
      |> Data.changeset(new_data)
      |> Repo.update()
    end
  end
  
  def commit(board_items, staging_items) do
    # Error if:
    # Any of staging_items placed in i j poistion that already has an item
    # All i position OR(||) all j position of staging_items have different number
    #   i.e. unique all(i) = 1 OR unique all(j) = 1
    # etc.
    
    board_items
    # |> validate(staging_items)
    |> Enum.concat(staging_items)
  end
  
  # struct -> map -> {:ok, new_data, number_of_commiited_items}
  def change_board(%{items: _} = game, %{"boardItems" => staging_items}) do
    new_data =
      game
      |> update_in([:items, :boardItems], &commit(&1, staging_items))
    
    {:ok, new_data, Enum.count(staging_items)}
  end

  # struct -> int -> {:ok, new_data, random-items}
  def change_rest(%{items: _} = game, _committed_count) do
    # random extract item from restItems by committed_count
    ramdom_items = []
    {:ok, update_in(game, [:items, :restItems], &(&1)), ramdom_items}
  end

  # struct -> map -> list -> {:ok, new_data}
  def change_mine(%{items: _} = game, %{"boardItems" => _staging_items}, ramdom_items) do
    # myitems = myitems - stagingItems
    # myitems = myitem + ramdom_items
    {:ok, update_in(game, [:items, :myItems], &(&1)) }
  end

  
  def find_and_update(list, item, value) do
    update_value = fn item_ ->
      if item_.item == item do
        %{item_ | item: value}
      else
        item_
      end
    end

    Enum.map(list, update_value)
  end

  @doc """
  Deletes a Item.

  ## Examples

      iex> delete_item(item)
      {:ok, %Item{}}

      iex> delete_item(item)
      {:error, %Ecto.Changeset{}}

  """
  def delete_item(%Item{} = item) do
    Repo.delete(item)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking item changes.

  ## Examples

      iex> change_item(item)
      %Ecto.Changeset{source: %Item{}}

  """
  def change_item(%Item{} = item) do
    item_changeset(item, %{})
  end

  defp item_changeset(%Item{} = item, attrs) do
    item
    |> cast(attrs, [:items])
    |> validate_required([])
  end
end
