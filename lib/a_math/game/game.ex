defmodule AMath.Game do
  @moduledoc """
  The boundary for the Game system.
  """
  import Ecto.{Query, Changeset}, warn: false
  alias AMath.Repo

  alias AMath.Game.Item
  alias AMath.Game.Data
  alias AMath.Game.Rule

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
    |> Data.changeset(attrs)
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

  # struct -> map -> {:ok, new_data, number_of_commiited_items}
  defp change_board(%{items: _} = game, %{"boardItems" => staging_items}) do
    new_data =
      case staging_items do
        [] ->
          game
        _ ->
          game
          |> update_in([:items, :boardItems], &commit(&1, staging_items))
      end
    
    {:ok, new_data, Enum.count(staging_items)}
  end

  defp commit(board_items, staging_items) do
    staging_items = Data.board_map(staging_items)
    all_items = Enum.concat(board_items, staging_items)

    case Rule.get_linear(staging_items) do
      {:constant_x, x, _min_y, _max_y} ->
        if Rule.is_connectable_x(all_items, staging_items, x) do
          all_items
        else
          board_items
        end
      {:constant_y, y, _min_x, _max_x} ->
        if Rule.is_connectable_y(all_items, staging_items, y) do
          all_items
        else
          board_items
        end
      {:point, x, y} ->
        x_ok = Rule.is_connectable_x(all_items, staging_items, x)
        y_ok = Rule.is_connectable_y(all_items, staging_items, y)
        
        case {x_ok, y_ok} do
          {true, _} -> all_items
          {_, true} -> all_items
          _ -> board_items
        end
      _ ->
        :no_op
    end
  end

  # map -> int -> {:ok, new_data, random-items}
  defp change_rest(%{items: _} = game, _committed_count) do
    # random extract item from restItems by committed_count
    ramdom_items = []
    {:ok, update_in(game, [:items, :restItems], &(&1)), ramdom_items}
  end

  # map -> map -> list -> {:ok, new_data}
  defp change_mine(%{items: _} = game, %{"boardItems" => _staging_items}, _random_items) do
    # myitems = myitems - stagingItems
    # myitems = myitem + ramdom_items
    {:ok, update_in(game, [:items, :myItems], &(&1)) }
  end

end
