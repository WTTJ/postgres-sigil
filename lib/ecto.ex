defmodule PostgresSigil.Ecto do
  alias PostgresSigil.Sql

  @moduledoc """
  Provides a query! function that calls through to Ecto
  """

  @doc """
  Syntax sugar to build the query string & pass it and bindings
  to Ecto.query!. We use apply to avoid depending explicitly on Ecto.
  """
  def query!(%Sql{statement: st, bindings: bi}, repo),
    do: Kernel.apply(Ecto.Adapters.SQL, :query!, [repo, st.(1), bi])
end
