defmodule AMath.Game do
  @moduledoc """
  The boundary for the Game system.
  """
  import Ecto.{Query, Changeset}, warn: false
  alias AMath.Repo
  alias AMath.Game.{Item, Data, Rule}

  def list_items do
    Repo.all(Item)
  end

  def get_item!(id) do
    Repo.get!(Item, id)
  end

  def create_item(attrs \\ %{}) do
    %Item{}
    |> Data.changeset(attrs)
    |> Repo.insert()
  end

  def update_commit(%Item{} = prev_data, attrs) do
    game = Data.to_map(prev_data)

    with {:ok, attrs} <- is_any_item(attrs),
      {:ok, new_data, committed_count} <- commit_board(game, attrs),
      {:ok, new_data, ramdom_items} <- take_rest(new_data, committed_count),
      {:ok, new_data} <- update_mine(new_data, attrs, ramdom_items) do
      
      prev_data
      |> Data.changeset(new_data)
      |> Repo.update()
    end
  end
  
  def update_exchange(%Item{} = prev_data, attrs) do
    game = Data.to_map(prev_data)
    exchanged_count = Enum.count(attrs["boardItems"])
    
    with {:ok, attrs} <- is_any_item(attrs),
      {:ok, new_data, ramdom_items} <- take_rest(game, exchanged_count),
      {:ok, new_data} <- add_rest(new_data, attrs),
      {:ok, new_data} <- update_mine(new_data, attrs, ramdom_items) do
    
      prev_data
      |> Data.changeset(new_data)
      |> Repo.update()
    end
  end

  def delete_item(%Item{} = item) do
    Repo.delete(item)
  end
  
  defp is_any_item(%{"boardItems" => staging_items} = attrs) do
    case staging_items  do
      [] ->
        {:error, :not_found}
      _ ->
        {:ok, attrs}
    end
  end

  defp commit_board(%{items: items} = game, %{"boardItems" => staging_items}) do
    with {:ok, new_board} <- commit(items.boardItems, staging_items) do
      new_data = update_in(game, [:items, :boardItems], fn _ -> new_board end)
      {:ok, new_data, Enum.count(staging_items)}
    else
      _ ->
        {:error, :not_found}
    end
  end

  defp commit(board_items, staging_items) do
    staging_items = Data.board_map(staging_items)
    all_items = Enum.concat(board_items, staging_items)

    case Rule.get_linear(staging_items) do
      {:constant_x, x, _min_y, _max_y} ->
        all_xitems = Rule.filter_sort(all_items, Rule.at_x(x), Rule.by_y)
        
        cond do
          board_items == [] &&
          # Rule.has_center_item(staging_items) &&
          Rule.is_continuous(staging_items, Rule.at_x(x), Rule.by_y) &&
          Rule.is_equation_correct(all_xitems) ->
            {:ok, all_items}

          {:ok, equations} =
            Rule.form_equation(all_xitems, staging_items, Rule.by_y, &Rule.at_y/1) ->
              Rule.has_xslot_gap(all_items, staging_items) &&
              Rule.is_equation_correct(equations) &&
              {:ok, all_items}

          true ->
            :no_op
        end
      {:constant_y, y, _min_x, _max_x} ->
        all_yitems = Rule.filter_sort(all_items, Rule.at_y(y), Rule.by_x)
        
        cond do
          board_items == [] &&
          # Rule.has_center_item(staging_items) &&
          Rule.is_continuous(staging_items, Rule.at_y(y), Rule.by_x) &&
          Rule.is_equation_correct(all_yitems) ->
            {:ok, all_items}

          {:ok, equations} =
            Rule.form_equation(all_yitems, staging_items, Rule.by_x, &Rule.at_x/1) ->
              Rule.has_yslot_gap(all_items, staging_items) &&
              Rule.is_equation_correct(equations) &&
              {:ok, all_items}

          true ->
            :no_op
        end
      {:point, x, y} ->
        all_xitems = Rule.filter_sort(all_items, Rule.at_x(x), Rule.by_y)
        all_yitems = Rule.filter_sort(all_items, Rule.at_y(y), Rule.by_x)

        cond do
          {:ok, x_equations} =
            Rule.form_equation(all_xitems, staging_items, Rule.by_y, &Rule.at_y/1) ->
              Rule.has_xslot_gap(all_items, staging_items) &&
              Rule.is_equation_correct(x_equations) &&
              {:ok, all_items}
              
          {:ok, y_equations} =
            Rule.form_equation(all_yitems, staging_items, Rule.by_x, &Rule.at_x/1) ->
              Rule.has_yslot_gap(all_items, staging_items) &&
              Rule.is_equation_correct(y_equations) &&
              {:ok, all_items}

          true ->
            :no_op
        end

      _ ->
        :no_op
    end
  end

  defp take_rest(%{items: _} = game, committed_count) do
    random_items = Rule.take_random_rest(game.items.restItems, committed_count)
  
    update_rest = fn (restItems, taking_items) ->
      taking_items = Data.compact_items(taking_items)

      restItems
      |> Enum.map(fn rest ->
        with {_item,ea} <- Enum.find(taking_items, &(elem(&1,0) == rest.item)) do
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
  
  defp add_rest(%{items: _} = game, %{"boardItems" => staging_items}) do
    exchanged_items = Data.board_map(staging_items)
    
    update_rest = fn (restItems, adding_items) ->
      adding_items = Data.compact_items(adding_items)

      restItems
      |> Enum.map(fn rest ->
        with {_item,ea} <- Enum.find(adding_items, &(elem(&1,0) == rest.item)) do
          %{rest | ea: rest.ea + ea}
        else
          nil -> rest
        end
      end)
    end

    {
      :ok,
      update_in(game, [:items, :restItems], &update_rest.(&1, exchanged_items))
    }
  end

  defp update_mine(%{items: _} = game, %{"boardItems" => staging_items}, random_items) do
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

    {:ok, update_in(game, [:items, :myItems], update_mine) }
  end

end
