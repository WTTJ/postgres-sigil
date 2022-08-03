defmodule PostgresSigil.Explain do
  import PostgresSigil.Results
  alias PostgresSigil.Sql
  import PostgresSigil

  @moduledoc """
  Utility for explaining queries.
  Rather than calling this directly you should use the
  explain_to_file! functions in Postgres / Ecto.
  """
  defp encode_json!(results),
    do: Application.get_env(:postgrex, :json_library, Jason).encode_to_iodata!(results)

  @doc """
  Surround the query in an explain call which also jsonifies the output,
  ready to be pasted into analysis tools like https://explain.dalibo.com/
  This module uses the same JSON library as Postgrex is configured to use.
  """
  @spec explain(Sql.t(), Keyword.t(), (Sql.t() -> %{})) :: Sql.t()
  def explain(sql = %Sql{}, opts, query) when is_function(query) do
    ~q"EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT JSON) #{sql}"
    |> query.()
    |> single_value!()
    |> encode_json!()
    |> write_to_file!(opts)
    sql
  end

  defp write_to_file!(iodata, opts),
    do: File.write!(Keyword.get(opts, :path, "explain.json"), iodata)
end
