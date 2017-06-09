defmodule AMath.Game do
  @moduledoc """
  The boundary for the Game system.
  """
  import Ecto.{Query, Changeset}, warn: false
  alias AMath.Repo

  import IEx
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
      
      # IEx.pry
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

  defp change_board(%{items: items} = game, %{"boardItems" => staging_items}) do
      case staging_items do
        [] ->
          {:error, :not_found}
        _ ->
          new_board = commit(items.boardItems, staging_items)

          if new_board == items.boardItems do
            {:error, :not_found}
          else
            new_data =
              game
              |> update_in([:items, :boardItems], fn _ -> new_board end)

            {:ok, new_data, Enum.count(staging_items)}
          end
      end
  end

  def commit(board_items, staging_items) do
    staging_items = Data.board_map(staging_items)
    all_items = Enum.concat(board_items, staging_items)

    case Rule.get_linear(staging_items) do
      {:constant_x, x, _min_y, _max_y} ->
        all_xitems = Rule.filter_sort(all_items, Rule.at_x(x), Rule.by_y)
        
        cond do
          board_items == [] && Rule.is_continuous(staging_items, Rule.at_x(x), Rule.by_y) ->
            Rule.is_equation_correct(all_items, :constant_x)

          Rule.is_connected(all_xitems, staging_items, Rule.by_y, &Rule.at_y/1) ->
            Rule.is_equation_correct(all_items, :constant_x)

          true ->
            board_items
        end
      {:constant_y, y, _min_x, _max_x} ->
        all_yitems = Rule.filter_sort(all_items, Rule.at_y(y), Rule.by_x)
        
        cond do
          board_items == [] && Rule.is_continuous(staging_items, Rule.at_y(y), Rule.by_x) ->
            Rule.is_equation_correct(all_items, :constant_y)

          Rule.is_connected(all_yitems, staging_items, Rule.by_x, &Rule.at_x/1) ->
            Rule.is_equation_correct(all_items, :constant_y)

          true ->
            board_items
        end
      {:point, x, y} ->
        all_xitems = Rule.filter_sort(all_items, Rule.at_x(x), Rule.by_y)
        x_ok = Rule.is_connected(all_xitems, staging_items, Rule.by_y, &Rule.at_y/1)
        
        all_yitems = Rule.filter_sort(all_items, Rule.at_y(y), Rule.by_x)
        y_ok = Rule.is_connected(all_yitems, staging_items, Rule.by_x, &Rule.at_x/1)
        
        case {x_ok, y_ok} do
          {true, _} -> all_items
          {_, true} -> all_items
          _ -> board_items
        end
      _ ->
        :no_op
    end
  end

  defp change_rest(%{items: _} = game, committed_count) do
    random_items =
      game.items.restItems
      |> Rule.take_random_rest(committed_count)
      
    update_rest = fn (restItems, rand_items) ->
      items_tuple =
        rand_items
        |> Enum.group_by(&(&1.item)) |> Enum.map(fn {k,v} -> {k,Enum.count(v)} end)
      
      restItems
      |> Enum.map(fn rest ->
        with {_item,ea} <- Enum.find(items_tuple, &(elem(&1,0) == rest.item)) do
          %{rest | ea: rest.ea - ea}
        else
          nil -> rest
        end
      end)
    end

    {
      :ok,
      update_in(game, [:items, :restItems], &update_rest.(&1, random_items)),
      random_items
    }
  end

  defp change_mine(%{items: _} = game, %{"boardItems" => staging_items}, random_items) do
    staging_items = Data.board_map(staging_items)

    update_mine = fn myItems ->
      staging_items = Enum.map(staging_items, &(&1.item))
      myItems_ = Enum.map(myItems, &(&1.item))
    
      myItems =
        (myItems_ -- staging_items)
        |> Enum.map(fn str -> Enum.find(myItems, &(&1.item == str)) end)
      
      myItems
      |> Enum.concat(Enum.map(random_items, &(%{item: &1.item, point: &1.point})))
    end

    # IEx.pry
    {:ok, update_in(game, [:items, :myItems], update_mine) }
  end

end
