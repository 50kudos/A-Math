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

  def is_continuous(items, const_fn, every_fn) when is_list(items) do
    items = Enum.filter(items, const_fn)

     case Enum.count(items) do
       0 ->
         false
       count ->
         [first|rest] = items
           |> Enum.map(every_fn)
           |> Enum.sort()
   
         # Sn = n(2a+(n-1)d)/2 where d = 1
         Enum.sum([first|rest]) == (count * (2 * first + count - 1) / 2)
     end
  end
  
  def at_x(x), do: fn(a) -> a.i == x end
  def at_y(y), do: fn(a) -> a.j == y end
  
  def by_x, do: fn(a) -> a.i end
  def by_y, do: fn(a) -> a.j end
  
  def filter_sort(items, f_axis, f_by) do
    items
    |> Enum.filter(f_axis)
    |> Enum.sort_by(f_by)
  end
  
  def is_connected(items, staging_items, f_by, f_at) do
    staging_index = Enum.map(staging_items, f_by)
    index_chunks = Enum.chunk_by(0..board_size(), fn axis ->
      Enum.any?(items, f_at.(axis)) # magic!
    end)
      
    # IEx.pry
    Enum.any?(index_chunks, fn index_chunk ->
      staging_index -- index_chunk == [] &&
      Enum.count(index_chunk) > Enum.count(staging_items)
    end)
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
