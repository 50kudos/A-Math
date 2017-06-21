defmodule AMath.Game.Rule do
  alias AMath.Game.Data

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
  
  def has_xslot_gap(all, items) do
    Enum.all?(items, fn a ->
      not Enum.any?(all, fn a0 ->
        a0.j == a.j && (a0.i == a.i + 1 || a0.i == a.i - 1)
      end)
    end)
  end
  
  def has_yslot_gap(all, items) do
    Enum.all?(items, fn a ->
      not Enum.any?(all, fn a0 ->
        a0.i == a.i && (a0.j == a.j + 1 || a0.j == a.j - 1)
      end)
    end)
  end
  
  def has_center_item(items) do
    Enum.any?(items, &(&1.i == board_size()/2 && &1.j == board_size()/2))
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
  
  def form_equation(items, staging_items, f_by, f_at) do
    staging_index = Enum.map(staging_items, f_by)
    
    index_chunk =
      0..board_size()
      |> Enum.chunk_by(fn axis -> Enum.any?(items, f_at.(axis)) end)
      |> Enum.find(fn index_chunk -> staging_index -- index_chunk == [] &&
           Enum.count(index_chunk) > Enum.count(staging_items) end)
    
    if index_chunk do
      {:ok, Enum.filter(items, fn item -> Enum.member?(index_chunk, f_by.(item)) end)}
    end
  end
  
  def take_random_rest(items, n) when is_integer(n) do
    items
    |> Data.expand_items()
    |> Enum.shuffle()
    |> Enum.take_random(n)
  end
  
  def is_equation_correct(items) do
    items = Enum.map(items, &(&1.value))

    with true <- Enum.member?(items, "="),
      {:ok, equations} <- calculable_map(items) |> IO.inspect,
      {:ok, _exprs} <- validate_expr(equations) |> IO.inspect,
      {:ok, ast} <- validate_syntax(equations) |> IO.inspect,
      :ok <- Macro.validate(ast)
    do
      all_expressions_matched?(ast)
    else
      _ -> false
    end
  end

  defp all_expressions_matched?(ast) do
    try do
      case Code.eval_quoted(ast) |> IO.inspect do
        {:error, _} -> false
        _ -> true
      end
    rescue
      MatchError -> false
      ArithmeticError -> false
    end
  end
  
  defp validate_syntax(equations) when is_list(equations) do
    with {:ok, ast} <- Code.string_to_quoted(Enum.join(equations)) do
      {:ok, validate_ast(ast)}
    end
  end
  
  defp validate_ast({operator, line, [number]}) do
    case {operator, number} do
      {:-, a} when a != 0 ->
        {:-, line, [a/1]}
      _ ->
        {"Only unary minus with non-zero number is allowed"}
    end
  end
  defp validate_ast({operator, line, [left,right]}) do
    cond do
      is_integer(left) && is_integer(right) ->
        {operator, line, [left/1, right/1]}
      is_integer(left) ->
        {operator, line, [left/1, validate_ast(right)]}
      is_integer(right) ->
        {operator, line, [validate_ast(left), right/1]}
      true ->
        {operator, line, [validate_ast(left), validate_ast(right)]}
    end
  end
  
  defp validate_expr(expressions) do
    expressions = Enum.map(expressions, &to_string/1)
    # Repeating zero is equal to 0 in elixir, but it's not a valid game's rule.
    # Also, for sake of challenging, only 3 digit can be concatenated.
    validate = fn expr ->
      case expr do
        [_] ->
          true
        ["0","0"] ->
          false
        [a,b] ->
          is_digit(a) && is_digit(b)
        ["0","0","0"] ->
          false
        [a,b,c] ->
          is_digit(a) && is_digit(b) && is_digit(c)
        _ ->
          false
      end
    end

    expressions
    |> Enum.chunk_by(&is_calc_operator/1)
    |> Enum.all?(validate)
    |> if(do: {:ok, expressions}, else: {:error, expressions})
  end
  
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
  
  defp operators_map() do
    %{
      "+" => "+",
      "-" => "-",
      "x" => "*",
      "÷" => "/",
      "+/-" => "+",
      "x/÷" => "*",
      "=" => "="
    }
  end
  
  defp is_calc_operator(a) do
    operators_map()
    |> Map.values()
    |> Enum.member?(a)
  end
  
  defp to_operator(a) when is_binary(a) do
    Map.get(operators_map(), a) ||
      raise(ArgumentError, message: "Only + - x ÷ +/- x/÷ operators are supported.")
  end
  
  defp calculable_map(items) do
    items =
      Enum.map(items, fn item ->
        cond do
          is_digit(item) -> String.to_integer(item)
          is_tens(item) -> String.to_integer(item)
          is_operator(item) -> to_operator(item)
          true ->
            ArgumentError
            |> raise(message: "Only 0-20 and + - x ÷ are supported.")
        end
      end)
    
    {:ok, items}
  end
end
