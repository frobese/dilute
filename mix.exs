defmodule Dilute.MixProject do
  use Mix.Project

  def project do
    [
      app: :dilute,
      version: "0.2.0-dev",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "Dilute",
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 2.0"},
      {:absinthe, "~> 1.4"},
      {:ex_doc, "~> 0.19", only: :dev}
    ]
  end

  defp description() do
    "Absinthe integration based on Ecto schemata"
  end

  defp docs do
    [
      main: "Dilute",
      # source_ref: "v#{@version}",
      canonical: "http://hexdocs.pm/dilute",
      # logo: "guides/images/e.png",
      source_url: "https://github.com/frobese/dilute"
    ]
  end

  defp package() do
    [
      name: "dilute",
      maintainers: ["Hans Gödeke"],
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/frobese/dilute"}
    ]
  end
end
