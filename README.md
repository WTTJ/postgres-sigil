# Postgres Sigil

![CI build](https://github.com/ottatech/postgres-sigil/actions/workflows/config.yml/badge.svg)
[![Hex.pm Version](https://img.shields.io/hexpm/v/postgres_sigil.svg?style=flat)](https://hex.pm/packages/postgres_sigil)
[![Hexdocs.pm](https://img.shields.io/static/v1?style=flat&label=hexdocs&message=postgres_sigil&color=blueviolet)](https://hexdocs.pm/postgres_sigil)

A library to improve the ergonomics of working with [Postgrex](https://github.com/elixir-ecto/postgrex).
It can be thought of as a middle ground between [Ecto](https://github.com/elixir-ecto/ecto) and 
[ayesql](https://github.com/alexdesousa/ayesql) in that the goal is to write queries in plain SQL 
but within Elixir source files, not separately. The syntax is heavily inspired by the Scala library [doobie](https://tpolecat.github.io/doobie/).

## Writing queries

### Basic selects

Use the `~q` sigil to construct queries. Variables can be safely interpolated into the query
and will be replaced with `$1`, `$2` etc positional parameters before being sent to Postgres.

```elixir
~q"SELECT * FROM users WHERE id = #{id}" |> to_tuple()
# result: {"SELECT * FROM users WHERE id = $1", [1245]}
```

### Fragments

Queries can be interpolated into other queries which allows you to re-use fragments.

```elixir
recently_seen = ~q"last_seen >= NOW() - INTERVAL '1 day'"
~q"SELECT * FROM users WHERE #{recently_seen}" |> to_tuple()
# result: {"SELECT * FROM users WHERE last_seen >= NOW() - INTERVAL '1 day'", []}
```

### Inserts and updates

Interpolating a call to `values()` will result in the value being enclosed in brackets
and prefixed with `VALUES`.

Note you cannot directly insert maps because they do not have a defined order.

```elixir
user = %{name: "Tom", email: "tom@example.com"}
~q"INSERT INTO users (name, email) #{values(user.name, user.email)}" |> to_tuple()
# result: {"INSERT INTO users (name, email) VALUES ($1, $2)", ["Tom", "tom@example.com"]}
```

The main benefit this syntax offers is that if you pass a list to `values` it'll generate
the correct SQL for a batch insert operation:

```elixir
~q"INSERT INTO users (name, email, address1) #{values([
  {"A", "a@a.com", "123 fake street"},
  {"B", "b@b.com", "234 fake street"}
])}" |> to_tuple()

# result: {
#  "INSERT INTO users (name, email, address1) VALUES ($1, $2, $3), ($4, $5, $6)",
#  ["A", "a@a.com", "123 fake street", "B", "b@b.com", "234 fake street"]
#}
```

### Dynamic columns

Column names can be interpolated by wrapping the interpolation in `col()`

```elixir
~q"SELECT #{col("name")} FROM users" |> to_tuple()
# result: {"SELECT \"name\" FROM users", []}
```

### Unsafe interpolation

If you're really up to no good then you can wrap interpolations in `unsafe()` which
will result in the value being directly placed into the query with no escaping.
This should only be used if you're fully aware of the [security implications](https://owasp.org/www-community/attacks/SQL_Injection).

```elixir
~q"SELECT #{unsafe("name")} FROM users"
# result: {"SELECT name FROM users", []}
```

## Running queries

You can run the queries either with Ecto or directly with Postgrex.

```elixir
~q"SELECT * FROM users" |> PostgresSigil.Ecto.query!(MyApp.Repo) # ecto
~q"SELECT * FROM users" |> PostgresSigil.Postgrex.query!(:pid) # postgrex
```

## Explaining queries

Both the Ecto and Postgrex integrations provide `explain_to_file!` that will
run the query with `EXPLAIN ANALYZE` and write the result to a file named `explain.json`.

This can then be pasted into https://explain.dalibo.com/ for analysis.

## Handling results

`PostgresSigil.Results` defines a number of functions to make it easier to process the results that Postgrex returns.

