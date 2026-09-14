defmodule MoriaClient.MixProject do
  use Mix.Project

  def project do
    [
      app: :moria_client,
      version: "0.35.1",
      elixir: ">= 1.18.4",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:tesla, "~> 1.15"},
      {:telemetry, "~> 1.0"},
      {:mint, "~> 1.0"},
      {:ecto, "~> 3.13"}
    ]
  end
end
