defmodule PostgresSigil do
  alias PostgresSigil.Sql

  @moduledoc """
  A sigil (~q) to make it easier to compose together SQL expressions.
  A SQL expression consists of a statement and interpolated variables.
  Expressions themselves can be interpolated and will be flattened.
  """

  defmodule Sql do
    @moduledoc """
    Struct that consists of a query statement and variable bindings
    """
    @enforce_keys [:statement, :bindings]
    defstruct [:statement, :bindings]

    @type t :: %__MODULE__{
            statement: (non_neg_integer() -> binary()),
            bindings: list(any())
          }
  end

  @doc """
  This macro rewrites interpolated values into calls to Siql.append
  For inserts and updates you can wrap the variables in values()
  """
  defmacro sigil_q({:<<>>, _, exprs}, []) do
    Enum.reduce(
      exprs,
      quote do
        PostgresSigil.lift("")
      end,
      fn
        # interpolate a values() call with one argument
        {:"::", _, [{_, _, [{:values, _, [var]}]}, _]}, acc ->
          quote do
            unquote(acc)
            |> PostgresSigil.append_unsafe("VALUES ")
            |> PostgresSigil.append_values(unquote(var))
          end

        # interpolate a values() call with multiple arguments
        {:"::", _, [{_, _, [{:values, _, vars}]}, _]}, acc ->
          quote do
            unquote(acc)
            |> PostgresSigil.append_unsafe("VALUES ")
            |> PostgresSigil.append_values(unquote({:{}, [], vars}))
          end

        {:"::", _, [{_, _, [{:unsafe, _, [var]}]}, _]}, acc ->
          quote do
            PostgresSigil.append_unsafe(unquote(acc), unquote(var))
          end

        {:"::", _, [{_, _, [{:col, _, [var]}]}, _]}, acc ->
          quote do
            PostgresSigil.append_identifier(unquote(acc), unquote(var))
          end

        {:"::", _, [{_, _, [var]}, _]}, acc ->
          quote do
            PostgresSigil.append(unquote(acc), unquote(var))
          end

        expr, acc when is_binary(expr) ->
          quote do
            PostgresSigil.append_unsafe(unquote(acc), unquote(expr))
          end
      end
    )
  end

  @doc """
  Turn the SQL into a tuple of the statement & bindings
  """
  def to_tuple(%Sql{statement: st, bindings: bi}),
    do: {st.(1), bi}

  @doc """
  Lift a plain string into a SQL expression with no variables
  """
  @spec lift(binary) :: Sql.t()
  def lift(a) when is_binary(a),
    do: %Sql{statement: fn _ -> a end, bindings: []}

  @doc """
  Append the given variable to the SQL expression.
  It will be added as position parameter and the value will go into bindings.
  Non boolean atoms will be converted into strings.
  """
  @spec append(Sql.t(), any()) :: Sql.t()
  def append(%Sql{statement: sta, bindings: ba}, %Sql{statement: stb, bindings: bb}),
    do: %Sql{
      statement: fn off -> "#{sta.(off)}#{stb.(off + (ba |> length))}" end,
      bindings: ba |> Enum.concat(bb)
    }

  def append(sql = %Sql{}, var) when is_atom(var) and not is_boolean(var),
    do: append(sql, var |> Atom.to_string())

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
  @spec append_values(Sql.t(), any) :: Sql.t()
  def append_values(sql = %Sql{}, tuple) when is_tuple(tuple),
    do:
      tuple
      |> Tuple.to_list()
      |> Enum.intersperse(lift(", "))
      |> Enum.reduce(append_unsafe(sql, "("), fn v, sql -> append(sql, v) end)
      |> append_unsafe(")")

  def append_values(sql = %Sql{}, var) when is_list(var),
    do:
      var
      |> Enum.map(fn v -> &append_values(&1, v) end)
      |> Enum.intersperse(&append_unsafe(&1, ", "))
      |> Enum.reduce(sql, fn fun, sql -> fun.(sql) end)

  def append_values(%Sql{}, %{}),
    do: raise("Maps cannot be sent as SQL values")

  def append_values(sql = %Sql{}, val),
    do: ~q"#{sql} (#{val})"

  @doc """
  Appends a DB identifier (i.e. a column name) to the query.
  It is enclosed in double quotes so any quotes within the name are escaped.
  """
  @spec append_identifier(Sql.t(), any) :: Sql.t()
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
  @spec append_unsafe(Sql.t(), any) :: Sql.t()
  def append_unsafe(%Sql{statement: st, bindings: bi}, item),
    do: %Sql{statement: fn off -> "#{st.(off)}#{item}" end, bindings: bi}
end
