defmodule PostgresSigil.ExplainTest do
  use ExUnit.Case, async: true
  import PostgresSigil.Explain
  alias PostgresSigil.Sql
  import PostgresSigil

  test "Should return the original query" do
    sql = ~q"SELECT 1"
    assert sql == explain(sql, [], fn _ -> %{rows: [[%{output: "json"}]]} end)
    File.rm!("explain.json")
  end

  test "Should write the query result to explain.json" do
    explain(~q"SELECT 1", [], fn
      %Sql{statement: stmt, bindings: []} ->
        exp = "EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT JSON) SELECT 1"
        assert stmt.(1) == exp
        %{rows: [[%{output: "json"}]]}
    end)

    assert ~s({"output":"json"}) == File.read!("explain.json")
    File.rm!("explain.json")
  end

  test "Should use a different path if one is provided" do
    explain(~q"SELECT 1", [path: "foo.json"], fn _ -> %{rows: [[%{output: "json"}]]} end)
    assert ~s({"output":"json"}) == File.read!("foo.json")
    File.rm!("foo.json")
  end
end
