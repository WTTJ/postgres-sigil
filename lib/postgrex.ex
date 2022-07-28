defmodule PostgresSigil.Postgrex do
  alias PostgresSigil.Sql

  @moduledoc """
  Provides a query! function that calls through to Postgrex
  """

  @doc """
  Syntax sugar to build the query string & pass it and bindings
  to Postgrex.query!. We use apply to avoid depending explicitly on Postgrex.
  """
  def query!(%Sql{statement: st, bindings: bi}, pid),
    do: Kernel.apply(Postgrex, :query!, [pid, st.(1), bi])
end
