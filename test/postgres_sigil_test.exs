defmodule PostgresSigilTest do
  use ExUnit.Case, async: true
  alias PostgresSigil.Sql
  import PostgresSigil

  test "Should generate correct interpolated expressions" do
    %Sql{statement: st, bindings: ["c"]} = ~q"SELECT * FROM a WHERE b = #{"c"}"
    assert st.(0) == "SELECT * FROM a WHERE b = $0"
  end

  test "Should adjust offsets for nested interpolations" do
    where = ~q"foo = #{1} AND bar = #{2}"
    %Sql{statement: st, bindings: bs} = ~q"SELECT * FROM a WHERE #{where} AND baz = #{3}"
    assert st.(0) == "SELECT * FROM a WHERE foo = $0 AND bar = $1 AND baz = $2"
    assert [1, 2, 3] = bs
  end

  test "Should add bindings and enclose them in brackets when values() is used" do
    %Sql{statement: st, bindings: bs} = ~q"INSERT INTO a #{values("a", "2")}"
    assert st.(0) == "INSERT INTO a VALUES ($0, $1)"
    assert ["a", "2"] = bs
  end

  test "Should allow a tuple2 to be passed for a dynamic number of values" do
    %Sql{statement: st, bindings: bs} = ~q"INSERT INTO a #{values({"a", "2"})}"
    assert st.(0) == "INSERT INTO a VALUES ($0, $1)"
    assert ["a", "2"] = bs
  end

  test "Should allow a tuple3 to be passed for a dynamic number of values" do
    %Sql{statement: st, bindings: bs} = ~q"INSERT INTO a #{values({"a", "2", "c"})}"
    assert st.(0) == "INSERT INTO a VALUES ($0, $1, $2)"
    assert ["a", "2", "c"] = bs
  end

  test "Should pass non top level lists as a single variable to postgres" do
    %Sql{statement: st, bindings: bs} = ~q"INSERT INTO a #{values({["a", "2", "c"]})}"
    assert st.(0) == "INSERT INTO a VALUES ($0)"
    assert [["a", "2", "c"]] = bs
  end

  test "Should escape identifiers when col() is used" do
    %Sql{statement: st, bindings: bs} = ~q"SELECT #{col("a\"b")}"
    assert st.(0) == ~S(SELECT "a\"b")
    assert [] = bs
  end

  test "Should allow unescaped interpolation with unsafe()" do
    %Sql{statement: st, bindings: bs} = ~q"SELECT #{unsafe("Robert');DROP TABLE students;--")}"
    assert st.(0) == "SELECT Robert');DROP TABLE students;--"
    assert [] = bs
  end
end
