defmodule Boltun.Mixfile do
  use Mix.Project

  def project do
    [app: :boltun,
     version: "0.0.2",
     elixir: "~> 1.0",
     deps: deps,
     package: package,
     description: description,
     docs: [readme: "README.md", main: "README"]]
  end

  def application do
    [applications: [:postgrex, :logger]]
  end

  defp deps do
    [{:postgrex, "~> 0.7"},
     {:earmark, "~> 0.1", only: :docs},
     {:ex_doc, "~> 0.6", only: :docs}]
  end

  defp description do
    "Transforms notifications from the Postgres LISTEN/NOTIFY mechanism into callback execution"
  end

  defp package do
    [contributors: ["Michele Balistreri"],
     licenses: ["ISC"],
     links: %{"GitHub" => "https://github.com/briksoftware/boltun"}]
  end
end
