defmodule AMath.Game.Rule do
  alias AMath.Game.Data

  defp board_size() do
    15 - 1 # For zero based index
  end

  defp is_digit(a) when is_binary(a)  do
    0..9
    |> Enum.map(&to_string/1)
    |> Enum.member?(a)
  end
  
  defp is_tens(a) when is_binary(a) do
    10..20
    |> Enum.map(&to_string/1)
    |> Enum.member?(a)
  end
  
  defp is_operator(a) when is_binary(a) do
    Enum.member? ~w(+ - x ÷ +/- x/÷ =), a
  end
  
  defp to_operator(a) when is_binary(a) do
    case a do
      "+" ->
        a
      "-" ->
        a
      "x" ->
        "*"
      "÷" ->
        "/"
      "+/-" ->
        "+"
      "x/÷" ->
        "*"
      "=" ->
        "=="
      _ ->
        ArgumentError
        |> raise(message: "Only + - x ÷ +/- x/÷ operators are supported.")
    end
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
  
  def is_equation_correct(items) do
    items = Enum.map(items, &(&1.item))
    
    with {:ok, equations} <- IO.inspect(calculable_map(items)),
      {:ok, ast} <- IO.inspect(validate_syntax(equations)),
      {:ok, _} <- IO.inspect(validate_expr(items)),
      {equality, _} <- IO.inspect(Code.eval_quoted(ast)) do
      
      equality
    else
      _ ->
        false
    end
  end
  
  def validate_syntax(equations) when is_list(equations) do
    Enum.join(equations) |> Code.string_to_quoted()
  end
  
  def validate_expr(expressions) do
    validate = fn expr ->
      case expr do
        [_] ->
          true
        [a,b] ->
          is_digit(a) && is_digit(b)
        [a,b,c] ->
          is_digit(a) && is_digit(b) && is_digit(c)
        _ ->
          false
      end
    end

    expressions
    |> Enum.chunk_by(&is_operator/1)
    |> Enum.all?(validate)
    |> if(do: {:ok, expressions}, else: {:error, expressions})
  end
  
  def calculable_map(items) do
    items =
      Enum.map(items, fn item ->
        cond do
          is_digit(item) -> String.to_integer(item)
          is_tens(item) -> String.to_integer(item)
          is_operator(item) -> to_operator(item)
          is_blank(item) -> 1
          true ->
            ArgumentError
            |> raise(message: "Only 0-20 and + - x ÷ +/- x/÷ are supported.")
        end
      end)
    
    {:ok, items}
  end
end
