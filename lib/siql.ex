defmodule Siql do
  alias Siql.Sql

  @moduledoc """
  Utility to make it easier to compose together SQL expressions.
  A SQL expression consists of a statement and interpolated variables.
  Expressions themselves can be interpolated and will be flattened.
  """

  defmodule Sql do
    @enforce_keys [:statement, :bindings]
    defstruct [:statement, :bindings]
  end

  @doc """
  This macro rewrites interpolated values into calls to Siql.append
  For inserts and updates you can wrap the variables in values()
  """
  defmacro sigil_q({:<<>>, _, exprs}, []) do
    Enum.reduce(
      exprs,
      quote do
        Siql.lift("")
      end,
      fn
        # interpolate a values() call with one tupleN argument
        {:"::", _, [{_, _, [{:values, _, [{:{}, _, vars}]}]}, _]}, acc ->
          quote do
            unquote(acc)
            |> Siql.append_unsafe("VALUES")
            |> Siql.append_values(unquote({:{}, [], vars}))
          end

        # interpolate a values() call with one tuple2 argument
        {:"::", _, [{_, _, [{:values, _, [{a, b}]}]}, _]}, acc ->
          quote do
            unquote(acc)
            |> Siql.append_unsafe("VALUES")
            |> Siql.append_values(unquote({a, b}))
          end

        # interpolate a values() call with multiple arguments
        {:"::", _, [{_, _, [{:values, _, vars}]}, _]}, acc ->
          quote do
            unquote(acc)
            |> Siql.append_unsafe("VALUES")
            |> Siql.append_values(unquote({:{}, [], vars}))
          end

        {:"::", _, [{_, _, [{:unsafe, _, [var]}]}, _]}, acc ->
          quote do
            Siql.append_unsafe(unquote(acc), unquote(var))
          end

        {:"::", _, [{_, _, [{:col, _, [var]}]}, _]}, acc ->
          quote do
            Siql.append_identifier(unquote(acc), unquote(var))
          end

        {:"::", _, [{_, _, [var]}, _]}, acc ->
          quote do
            Siql.append(unquote(acc), unquote(var))
          end

        expr, acc when is_binary(expr) ->
          quote do
            Siql.append_unsafe(unquote(acc), unquote(expr))
          end
      end
    )
  end

  @doc """
  Lift a plain string into a SQL expression with no variables
  """
  @spec lift(binary) :: %Sql{}
  def lift(a) when is_binary(a),
    do: %Sql{statement: fn _ -> a end, bindings: []}

  @doc """
  Append the given variable to the SQL expression.
  It will be added as position parameter and the value will go into bindings
  """
  @spec append(%Sql{}, any()) :: %Sql{}
  def append(%Sql{statement: sta, bindings: ba}, %Sql{statement: stb, bindings: bb}),
    do: %Sql{
      statement: fn off -> "#{sta.(off)}#{stb.(off + (ba |> length))}" end,
      bindings: ba |> Enum.concat(bb)
    }

  def append(%Sql{statement: st, bindings: bi}, var),
    do: %Sql{
      statement: fn off -> "#{st.(off)}$#{off + (bi |> length)}" end,
      bindings: bi |> Enum.concat([var])
    }

  @doc """
  Append variable(s) to the SQL query enclosed in brackets, for inserts / updates.
  Multiple variables can be passed by using a tuple. Lists are interpreted to be bulk inserts,
  so will generate multiple bracket-enclosed sequences.
  """
  @spec append_values(%Sql{}, any) :: %Sql{}
  def append_values(sql = %Sql{}, var) when is_list(var),
    do: var |> Enum.reduce(sql, fn val, sql -> sql |> append_values(val) end)

  def append_values(sql = %Sql{}, tuple) when is_tuple(tuple) do
    case(Tuple.to_list(tuple)) do
      [h | ts] ->
        ~q"#{sql} (#{h}#{ts |> Enum.reduce(~q"", fn v, q -> ~q"#{q}, #{v}" end)})"

      [] ->
        sql
    end
  end

  def append_values(sql = %Sql{}, val),
    do: ~q"#{sql} (#{val})"

  @doc """
  Appends a DB identifier (i.e. a column name) to the query.
  It is enclosed in double quotes so any quotes within the name are escaped.
  """
  @spec append_identifier(%Siql.Sql{}, any) :: %Siql.Sql{}
  def append_identifier(%Sql{statement: st, bindings: bi}, col),
    do: %Sql{
      statement: fn off -> "#{st.(off)}\"#{col |> String.replace("\"", "\\\"")}\"" end,
      bindings: bi
    }

  @doc """
  Escape hatch for appending arbitrary data to the query without any escaping
  Obviously doing this can lead to SQL injection vulnerabilities so be careful
  but there are legitimate reasons to want to do this from time to time.
  """
  @spec append_unsafe(%Siql.Sql{}, any) :: %Siql.Sql{}
  def append_unsafe(%Sql{statement: st, bindings: bi}, item),
    do: %Sql{statement: fn off -> "#{st.(off)}#{item}" end, bindings: bi}
end
