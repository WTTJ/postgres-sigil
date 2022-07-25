defmodule PostgresSigil.MixProject do
  use Mix.Project

  def project do
    [
      app: :postgres_sigil,
      version: "0.1.0",
      elixir: "~> 1.12",
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: []
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.27", only: :dev, runtime: false}
    ]
  end
end
