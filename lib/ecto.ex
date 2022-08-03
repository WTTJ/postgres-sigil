defmodule PostgresSigil.Ecto do
  import PostgresSigil.Explain
  alias PostgresSigil.Sql

  @moduledoc """
  Provides functions to run queries with Ecto.
  """

  @doc """
  Run the query with explain and write it to a file.
  This is for debugging during development.
  """
  def explain_to_file!(query = %Sql{}, repo, opts \\ []),
    do: explain(query, opts, &query!(&1, repo))

  @doc """
  Syntax sugar to build the query string & pass it and bindings
  to Ecto.query!. We use apply to avoid depending explicitly on Ecto.
  """
  def query!(%Sql{statement: st, bindings: bi}, repo),
    do: Kernel.apply(Ecto.Adapters.SQL, :query!, [repo, st.(1), bi])
end
