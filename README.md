# Postgres Sigil

⚠️ Currently WIP

A library to improve the ergonomics of working with [Postgrex.](https://github.com/elixir-ecto/postgrex).
It can be thought of as a middle ground between [Ecto](https://github.com/elixir-ecto/ecto) and 
[ayesql](https://github.com/alexdesousa/ayesql) in that the goal is to write queries in plain SQL 
but within Elixir source files, not separately.

This is heavily inspired by the Scala library [doobie](https://tpolecat.github.io/doobie/).

## Writing queries

### Basic selects

Use the `~q` sigil to construct queries. Variables can be safely interpolated into the query
and will be replaced with `$1`, `$2` etc positional parameters before being sent to Postgres.

```elixir
import Siql

def find_user(id), 
  do:  ~q"SELECT * FROM users WHERE id = #{id}"
```

### Fragments

Queries can be interpolated into other queries which allows you to re-use fragments.

```elixir
def recently_seen(),
  do: ~q"last_seen >= NOW() - INTERVAL '1 day'"

def find_recent_user(id), 
  do:  ~q"SELECT * FROM users WHERE #{recently_seen()}"
```

### Inserts and updates

Interpolating a call to `values()` will result in the value being enclosed in brackets
and prefixed with `VALUES` - useful for taking some of the pain out of writing inserts.

```elixir
def insert_user(%User{name: name, email: email, address1: address1}),
  do: ~q"INSERT INTO users #{values(name, email, address1)}"
```

The main benefit this syntax offers is that if you pass a list to `values` it'll generate
the correct SQL for a batch insert operation:

```elixir
def insert_users(),
  do: ~q"INSERT INTO users #{values([
    {"A", "a@a.com", "123 fake street"},
    {"B", "b@b.com", "234 fake street"}
  ])}"
```

You can also call values with a tuple, which is occasionally useful if you're writing 
very dynamic queries and don't know at compile time how many columns you're inserting:

```elixir
def insert_user(%User{name: name, email: email, address1: address1}),
  do: ~q"INSERT INTO users #{values({name, email, address1})}
```

### Dynamic columns

Column names can be interpolated by wrapping the interpolation in `col()`

```elixir
def find_recent_user(id), 
  do:  ~q"SELECT #{col("name")} FROM users"
```

### Unsafe interpolation

If you're really up to no good then you can wrap interpolations in `unsafe()` which
will result in the value being directly placed into the query with no escaping.

This should only be used if you're fully aware of the [security implications](https://owasp.org/www-community/attacks/SQL_Injection).

```elixir
def find_recent_user(id), 
  do:  ~q"SELECT #{unsafe("name")} FROM users"
```

## Running queries

You can run the queries either with Ecto or directly with Postgrex.
`query!` functions for each are defined in `PostgresSigil.Postgrex` or `PostgresSigil.Ecto`.

## Handling results

`PostgresSigil.Results` defines a number of functions to make it easier to process the results that
Postgrex returns.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `PostgresSigil` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:postgres_sigil, "~> 0.1.0"}
  ]
end
```
