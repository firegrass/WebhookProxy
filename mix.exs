defmodule WebhookProxy.MixProject do
  use Mix.Project

  def project do
    [
      app: :webhook_proxy,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {WebhookProxy.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug_cowboy, "~> 2.0"},
      {:poison, "~> 5.0"},
      {:httpoison, "~> 1.8"},
      {:distillery, "~> 2.1"},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:mox, "~> 0.5", only: :test}
    ]
  end
end
