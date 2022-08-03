defmodule PostgresSigil.MixProject do
  use Mix.Project

  def project do
    [
      app: :postgres_sigil,
      deps: deps(),
      dialyzer: [plt_file: {:no_warn, "priv/plts/dialyzer.plt"}],
      elixir: "~> 1.13",
      package: package(),
      version: "0.1.0-dev"
    ]
  end

  defp package do
    [
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE),
      description: "A sigil to make it easier to safely write Postgres queries",
      links: %{"GitHub" => "https://github.com/OttaTech/postgres-sigil"},
      licenses: ["Apache-2.0"]
    ]
  end

  def application do
    [
      extra_applications: []
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:jason, "~> 1.3", only: [:dev, :test]},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false}
    ]
  end
end
