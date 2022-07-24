defmodule Siql.Postgrex do
  alias Siql.Sql

  @doc """
  Syntax sugar to build the query string & pass it and bindings
  to Postgrex.query!. We use apply to avoid depending explicitly on Postgrex.
  """
  def query!(%Sql{statement: st, bindings: bi}, pid) when is_pid(pid),
    do: Kernel.apply(Postgrex, :query!, [pid, st.(1), bi])
end
