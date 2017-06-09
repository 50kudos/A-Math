defmodule AMath.Game.Rule do
  import IEx
  alias AMath.Game.Data

  def board_size() do
    15 - 1 # For zero based index
  end

  def is_digit(a) when is_binary(a)  do
    0..9
    |> Enum.map(&to_string/1)
    |> Enum.member?(a)
  end
  
  def is_tens(a) when is_binary(a) do
    10..20
    |> Enum.map(&to_string/1)
    |> Enum.member?(a)
  end
  
  def is_operator(a) when is_binary(a) do
    Enum.member? ~w(+ - x ÷ +/- x/÷), a
  end
  
  def is_blank(a) when is_binary(a) do
    a == "blank"
  end

  def get_linear([%{i: x0,j: y0}|rest] = points) when is_list(points) do
    cond do
      rest == [] ->
        {:point, x0, y0}
      Enum.all?(rest, fn %{i: xn} -> xn == x0 end) ->
        {%{j: min_y}, %{j: max_y}} =
          points |> Enum.min_max_by(fn %{j: y} -> y end)

        {:constant_x, x0, min_y, max_y}
      Enum.all?(rest, fn %{j: yn} -> yn == y0 end) ->
        {%{i: min_x}, %{i: max_x}} =
          points |> Enum.min_max_by(fn %{i: x} -> x end)

        {:constant_y, y0, min_x, max_x}
      true ->
        :nothing
    end
  end

  # Sn = n(2a+(n-1)d)/2 where d = 1
  # Sn = n(2a+(n-1))/2
  def is_continuous(items, constant) when is_list(items) do
    {const_fn, every_fn} = linear_funtions(constant)
    items = Enum.filter(items, const_fn)

     case Enum.count(items) do
       0 ->
         false
       count ->
         [first|rest] = items
           |> Enum.map(every_fn)
           |> Enum.sort()

         Enum.sum([first|rest]) == (count * (2 * first + count - 1) / 2)
     end
  end
  
  defp linear_funtions(constant_x: x), do: {&(&1.i == x), &(&1.j)}
  defp linear_funtions(constant_y: y), do: {&(&1.j == y), &(&1.i)}
  
  def is_connectable_x(all_items, staging_items, x) do
    x_items =
      all_items
      |> Enum.filter(&(&1.i == x))
      |> Enum.sort_by(&(&1.j))
            
    staging_index = Enum.map(staging_items, &(&1.j))
    index_chunks = Enum.chunk_by(0..board_size(), fn j ->
      Enum.any?(x_items, &(&1.j == j))
    end)
      
    # IEx.pry
    Enum.any?(index_chunks, fn index_chunk ->
      staging_index -- index_chunk == [] &&
      Enum.count(index_chunk) > Enum.count(staging_items)
    end)
  end
  
  def is_connectable_y(all_items, staging_items, y) do
    y_items =
      all_items
      |> Enum.filter(&(&1.j == y))
      |> Enum.sort_by(&(&1.i))
            
    staging_index = Enum.map(staging_items, &(&1.i))
    index_chunks = Enum.chunk_by(0..board_size(), fn i ->
      Enum.any?(y_items, &(&1.i == i))
    end)
    
    Enum.any?(index_chunks, fn index_chunk ->
      staging_index -- index_chunk == [] &&
      Enum.count(index_chunk) > Enum.count(staging_items)
    end)
  end

  def get_axis_items(items, x: x) do
    items
    |> Enum.filter(&(&1.i == x))
    |> Enum.sort_by(&(&1.j))
  end
  
  def get_axis_items(items, y: y) do
    items
    |> Enum.filter(&(&1.j == y))
    |> Enum.sort_by(&(&1.i))
  end
  
  def take_random_rest(items, n) when is_integer(n) do
    items
    |> Data.expand_items()
    |> Enum.shuffle()
    |> Enum.take_random(n)
  end
  
  def is_equation_correct(items, :constant_x) do
    items
  end
  
  def is_equation_correct(items, :constant_y) do
    items
  end
  
  
end
