defmodule Siql.Ecto do
  alias Siql.Sql

  @doc """
  Syntax sugar to build the query string & pass it and bindings
  to Ecto.query!. We use apply to avoid depending explicitly on Ecto.
  """
  def query!(%Sql{statement: st, bindings: bi}, repo),
    do: Kernel.apply(Ecto.Adapters.SQL, :query!, [repo, st.(1), bi])
end
