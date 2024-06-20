defmodule Spider.MixProject do
  use Mix.Project

  def project do
    [
      app: :spider,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Spider.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:exgbk, path: "./3rd_libs/exgbk"},
      {:redix, "~> 1.1"},
      {:castore, "~> 1.0"},
      {:jason, "~> 1.4"},
      {:floki, "~> 0.35.0"},
      {:httpoison, "~> 2.2.1"},
      {:timex, "~> 3.0"},
      {:quantum, "~> 3.5.0"}
    ]
  end
end
