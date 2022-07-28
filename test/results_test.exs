defmodule PostgresSigil.ResultsTest do
  use ExUnit.Case, async: true
  import PostgresSigil.Results

  describe "single_value_or_nil" do
    test "Should return nil when no results are returned" do
      assert %{rows: [[nil]]} |> single_value_or_nil!() |> is_nil()
      assert %{rows: nil} |> single_value_or_nil!() |> is_nil()
      assert %{rows: []} |> single_value_or_nil!() |> is_nil()
    end

    test "Should fail when too many columns are returned" do
      %{rows: [["a", "b"]]} |> single_value_or_nil!() |> catch_error()
    end

    test "Should fail when too many rows are returned" do
      %{rows: [["a"], ["b"]]} |> single_value_or_nil!() |> catch_error()
    end

    test "Should apply the provided function to the single value" do
      assert :a = %{rows: [["a"]]} |> single_value_or_nil!(&String.to_atom/1)
    end
  end

  describe "single_value!" do
    test "Should fail when provided no rows or a nil row" do
      %{rows: [[nil]]} |> single_value!() |> catch_error()
      %{rows: []} |> single_value!() |> catch_error()
    end

    test "Should succeed given exactly one row" do
      assert "a" = %{rows: [["a"]]} |> single_value!()
    end
  end

  describe "exists" do
    test "Returns whether num_rows is greater than zero" do
      assert not exists(%{num_rows: 0})
      assert exists(%{num_rows: 1})
    end
  end

  describe "to_maps" do
    test "Should zip the returned column names with the values for each row" do
      assert [
               %{"a" => 1, "b" => "first"},
               %{"a" => 2, "b" => "second"}
             ] = to_maps(%{columns: ["a", "b"], rows: [[1, "first"], [2, "second"]]})
    end

    test "Should use atom keys if keys: :atoms is passed" do
      assert [
               %{a: 1, b: "first"},
               %{a: 2, b: "second"}
             ] =
               to_maps(
                 %{columns: ["a", "b"], rows: [[1, "first"], [2, "second"]]},
                 keys: :atoms
               )
    end
  end

  describe "to_structs!" do
    defmodule TestStruct do
      @enforce_keys [:a, :b]
      defstruct [:a, :b]
    end

    test "Should turn the columns into structs" do
      assert [
               %TestStruct{a: 1, b: "first"},
               %TestStruct{a: 2, b: "second"}
             ] =
               to_structs!(
                 %{columns: ["a", "b"], rows: [[1, "first"], [2, "second"]]},
                 TestStruct
               )
    end

    test "Should fail if a key is missing" do
      catch_error(to_structs!(%{columns: ["a"], rows: [[1], [2]]}, TestStruct))
    end
  end
end
