defmodule AMath.Game do
  @moduledoc """
  The boundary for the Game system.
  """
  import IEx
  import Ecto.{Query, Changeset}, warn: false
  alias AMath.Repo
  alias AMath.Game.{Item, Data, Rule, Board}
  
  @deck_size 8
  @bingo_bonus 40
  
  def create_item() do
    initial_data = AMath.Game.Intializer.sample()
    
    with {:ok, game, p1_items} <- take_rest(initial_data, @deck_size),
      {:ok, game, p2_items} <- take_rest(game, @deck_size)
    do
      game = game
      |> put_deck(:p1_deck, p1_items)
      |> put_deck(:p2_deck, p2_items)

      %Item{game_id: generate_game_id()}
      |> Data.changeset(game)
      |> Repo.insert()
    end
  end
  
  def put_deck(game, deck_key, items) do
    deck_items = %{items: Enum.map(items, &(Map.take &1, [:item, :point])), point: 0}
    %{game | items: Map.put(game.items, deck_key, deck_items)}
  end
  
  def update_commit(%Item{} = prev_data, attrs, deck_key) do
    game = Data.to_map(prev_data)

    with {:ok, attrs} <- is_any_item(attrs),
      {:ok, new_data, committed_count, point} <- commit_board(game, attrs),
      {:ok, new_data, taken_items} <- take_rest(new_data, committed_count),
      {:ok, new_data} <- update_mine(new_data, attrs, taken_items, deck_key),
      {:ok, new_data} <- update_point(new_data, point, deck_key),
      {:ok, new_data} <- reset_pass_count(new_data)
    do
      prev_data
      |> Data.changeset(new_data)
      |> Repo.update()
    end
  end
  
  def update_exchange(%Item{} = prev_data, attrs, deck_key) do
    game = Data.to_map(prev_data)
    exchanged_count = Enum.count(attrs["boardItems"])

    with {:ok, attrs} <- is_any_item(attrs),
      {:ok, new_data, taken_items} <- take_rest(game, exchanged_count),
      {:ok, new_data, taken_items} <- handle_if_empty_rest(new_data, taken_items),
      {:ok, new_data} <- add_rest(new_data, attrs),
      {:ok, new_data} <- update_mine(new_data, attrs, taken_items, deck_key)
    do
      prev_data
      |> Data.changeset(new_data)
      |> Repo.update()
    end
  end
  
  def handle_if_empty_rest(%{items: _}, []), do: {:error, %{reason: :empty_rest}}
  def handle_if_empty_rest(%{items: _} = game, taken_items), do: {:ok, game, taken_items}
  
  def enqueue_deck(game, fun \\ fn x -> x end) do
    new_game = game
    |> Data.to_map()
    |> update_in([:items, :turn_queue], fun)

    game
    |> Data.changeset(new_game)
    |> Repo.update()
  end
  
  def rotate_turn(game) do
    enqueue_deck(game, fn [first|rest] -> rest ++ [first] end)
  end
  
  def reset_game(id) do
    initial_data = AMath.Game.Intializer.sample()
    
    with {:ok, game, p1_items} <- take_rest(initial_data, @deck_size),
      {:ok, game, p2_items} <- take_rest(game, @deck_size)
    do
      game = game
      |> put_deck(:p1_deck, p1_items)
      |> put_deck(:p2_deck, p2_items)

      get_item!(id)
      |> Data.changeset(game)
      |> Repo.update()
    end
  end

  def list_items do
    Repo.all(Item)
  end

  def get_item!(id) do
    Repo.get_by!(Item, game_id: id)
  end
  
  def generate_game_id() do
    :crypto.strong_rand_bytes(32) |> Base.url_encode64() |> binary_part(0, 32)
  end

  def delete_item(%Item{} = item) do
    Repo.delete(item)
  end
  
  def is_any_item(%{"boardItems" => staging_items} = attrs) do
    case staging_items  do
      [] ->
        {:error, :not_found}
      _ ->
        {:ok, attrs}
    end
  end

  def commit_board(%{items: items} = game, %{"boardItems" => staging_items}) do
    with {:ok, new_board, cont_items} <- commit(items.boardItems, staging_items)
    do
      {:ok,
        update_in(game, [:items, :boardItems], fn _ -> new_board end),
        Enum.count(staging_items),
        calculate_point(staging_items, cont_items)
      }
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
          Rule.has_center_item(staging_items) &&
          Rule.is_continuous(staging_items, Rule.at_x(x), Rule.by_y) &&
          Rule.is_equation_correct(all_xitems) ->
            {:ok, all_items, all_xitems}

          true ->
            with {:ok, equations} <- Rule.form_equation(all_xitems, staging_items, Rule.by_y, &Rule.at_y/1),
              true <- Rule.has_xslot_gap(all_items, staging_items),
              true <- Rule.is_equation_correct(equations) do
              
              {:ok, all_items, equations}
            else
              _ -> :no_op
            end
        end
      {:constant_y, y, _min_x, _max_x} ->
        all_yitems = Rule.filter_sort(all_items, Rule.at_y(y), Rule.by_x)
        
        cond do
          board_items == [] &&
          Rule.has_center_item(staging_items) &&
          Rule.is_continuous(staging_items, Rule.at_y(y), Rule.by_x) &&
          Rule.is_equation_correct(all_yitems) ->
            {:ok, all_items, all_yitems}

          true ->
            with {:ok, equations} <- Rule.form_equation(all_yitems, staging_items, Rule.by_x, &Rule.at_x/1),
              true <- Rule.has_yslot_gap(all_items, staging_items),
              true <- Rule.is_equation_correct(equations) do
              
              {:ok, all_items, equations}
            else
              _ -> :no_op
            end
        end
      {:point, x, y} ->
        all_xitems = Rule.filter_sort(all_items, Rule.at_x(x), Rule.by_y)
        all_yitems = Rule.filter_sort(all_items, Rule.at_y(y), Rule.by_x)

        with {:ok, x_equations} <- Rule.form_equation(all_xitems, staging_items, Rule.by_y, &Rule.at_y/1),
          true <- Rule.has_xslot_gap(all_items, staging_items),
          true <- Rule.is_equation_correct(x_equations) do

          {:ok, all_items, x_equations}
        else
          _ ->
            with {:ok, y_equations} <- Rule.form_equation(all_yitems, staging_items, Rule.by_x, &Rule.at_x/1),
              true <- Rule.has_yslot_gap(all_items, staging_items),
              true <- Rule.is_equation_correct(y_equations) do
             
              {:ok, all_items, y_equations}
            else
              _ -> :no_op
            end
        end

      _ ->
        :no_op
    end
  end

  def take_rest(%{items: _} = game, taking_count) do
    random_items = Rule.take_random_rest(game.items.restItems, taking_count)
    
    updated_rest = update_in(game, [:items, :restItems], fn rest ->
      update_rest(rest, random_items, &Kernel.-/2)
    end)
    
    {:ok, updated_rest, random_items}
  end

  defp add_rest(%{items: _} = game, %{"boardItems" => staging_items}) do
    exchanged_items = Data.board_map(staging_items)

    updated_rest = update_in(game, [:items, :restItems], fn rest ->
      update_rest(rest, exchanged_items, &Kernel.+/2)
    end)
    
    {:ok, updated_rest}
  end
  
  defp update_rest(restItems, items, fun) do
    items = Data.compact_items(items)

    restItems
    |> Enum.map(fn rest ->
      with {_item,ea} <- Enum.find(items, &(elem(&1,0) == rest.item)) do
        %{rest | ea: fun.(rest.ea, ea)}
      else
        nil -> rest
      end
    end)
  end

  def update_mine(%{items: _} = game, %{"boardItems" => staging_items}, random_items, deck_key \\ nil) do
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

    {:ok, update_in(game, [:items, deck_key, :items], update_mine)}
  end
  
  def calculate_point(staging_items, cont_items) do
    staging_items = Data.board_map(staging_items)
    const_board_items = MapSet.difference(MapSet.new(cont_items), MapSet.new(staging_items))

    total_point = staging_items
    |> Enum.reduce(0, fn (item,acc) -> Board.piece_point(item) + acc end)
    |> Kernel.+(Enum.reduce(const_board_items, 0, fn (item,acc) -> item.point + acc end))
    |> Kernel.*(Enum.reduce(staging_items, 1, fn (item,acc) -> Board.equation_mult(item) * acc end))
    
    if Enum.count(staging_items) == @deck_size, do: total_point + @bingo_bonus, else: total_point
  end
  
  def update_point(%{items: _} = game, point, deck_key) do
    {:ok, update_in(game, [:items, deck_key, :point], &(&1 + point))}
  end
  
  def get_deck(game, deck_id) do
    if deck_id == game.items.p1_deck.id do
      Map.get(game.items, :p1_deck) |> Map.put(:key, :p1_deck)
    else
      Map.get(game.items, :p2_deck) |> Map.put(:key, :p2_deck)
    end
  end
  
  def get_rest_for(game_items, deck_id) do
    %{items: items} = Data.to_map(%{items: game_items})

    cond do
      items.p1_deck.id == deck_id ->
        update_rest(items.restItems, items.p2_deck.items, &Kernel.+/2)
      true ->
        update_rest(items.restItems, items.p1_deck.items, &Kernel.+/2)
    end
  end
  
  def any_rest?(%{restItems: rest}) do
    rest
    |> Data.expand_items()
    |> Enum.count()
    |> Kernel.!==(0)
  end
  
  def pass_turn(%Item{} = game, [], _deck_key) do
    new_game = update_in(Data.to_map(game), [:items, :passed], &(&1 + 1))
    
    game
    |> Data.changeset(new_game)
    |> Repo.update()
  end
  
  def reset_pass_count(%{items: _} = game) do
    {:ok, update_in(game, [:items, :passed], &(&1 * 0))}
  end
  
  def ended_status(%Data{} = data) do
    cond do
      data.passed >= 3 ->
        :passing_ended
      data.p1_deck.items == [] || data.p2_deck.items == [] ->
        :deck_ended
      true ->
        :running
    end
  end
  
  def handle_turn([], _deck_id), do: false
  def handle_turn([first|_], deck_id), do: first == deck_id
end
