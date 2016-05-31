defmodule Boltun.Mixfile do
  use Mix.Project

  def project do
    [app: :boltun,
     version: "1.0.1",
     elixir: "~> 1.0",
     deps: deps,
     package: package,
     description: description]
  end

  def application do
    [applications: [:postgrex, :logger]]
  end

  defp deps do
    [{:postgrex, ">= 0.11.0"},
    {:earmark, "~> 0.2", only: :dev},
    {:ex_doc, "~> 0.11", only: :dev}]
  end

  defp description do
    "Transforms notifications from the Postgres LISTEN/NOTIFY mechanism into callback execution"
  end

  defp package do
    [maintainers: ["Michele Balistreri"],
     licenses: ["ISC"],
     links: %{"GitHub" => "https://github.com/bitgamma/boltun"}]
  end
end
