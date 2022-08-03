defmodule PostgresSigil.Postgrex do
  import PostgresSigil.Explain
  alias PostgresSigil.Sql

  @moduledoc """
  Provides functions to run queries with Postgrex.
  """

  @doc """
  Run the query with explain and write it to a file.
  This is for debugging during development.
  """
  def explain_to_file!(query = %Sql{}, pid, opts \\ []),
    do: explain(query, opts, &query!(&1, pid))

  @doc """
  Syntax sugar to build the query string & pass it and bindings to Postgrex.query!.
  We use apply to avoid depending explicitly on Postgrex.
  """
  def query!(%Sql{statement: st, bindings: bi}, pid),
    do: Kernel.apply(Postgrex, :query!, [pid, st.(1), bi])
end
