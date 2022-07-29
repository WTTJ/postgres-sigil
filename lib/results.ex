defmodule PostgresSigil.Results do
  @moduledoc """
  Functions that operate on Postgrex results
  to make it easier to extract values from them
  """

  @doc """
  Given a result set, ensure it either contains exactly one value
  or no values at all, in which case nil will be returned.
  The second argument is an optional function to apply to the value if it isn't nil.
  """
  def single_value_or_nil!(results, function \\ nil)

  def single_value_or_nil!(%{rows: [[value]]}, _) when is_nil(value),
    do: nil

  def single_value_or_nil!(%{rows: [[value]]}, function) when not is_nil(function),
    do: function.(value)

  def single_value_or_nil!(%{rows: [[value]]}, _),
    do: value

  def single_value_or_nil!(%{rows: rows}, _) when is_nil(rows) or rows == [],
    do: nil

  @doc """
  Given a result set, ensure it either contains exactly one value.
  In all other cases a match error will be thrown
  """
  def single_value!(%{rows: [[value]]}) when not is_nil(value),
    do: value

  @doc """
  Extract the number of rows affected by the SQL operation
  """
  def num_rows(%{num_rows: num_rows}),
    do: num_rows

  @doc """
  Returns whether any rows have come back
  """
  def exists(%{num_rows: num_rows}),
    do: num_rows > 0

  @doc """
  Zip the returned column names with the rows to produce a list of maps,
  where each key is the column name.
  """
  def to_maps(%{columns: cols, rows: rows}, [keys: keys] \\ [keys: :strings]) do
    cols =
      if keys == :atoms do
        Enum.map(cols, &String.to_existing_atom/1)
      else
        cols
      end

    Enum.map(rows, fn row -> Map.new(Enum.zip(cols, row)) end)
  end

  @doc """
  Turn the results into a list of maps, then turn them into a struct.
  If any required keys are missing an exception will be raised.
  """
  def to_structs!(results = %{columns: _, rows: _}, struct),
    do: to_maps(results, keys: :atoms) |> Enum.map(&Kernel.struct!(struct, &1))
end
