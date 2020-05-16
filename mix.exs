defmodule Dilute.MixProject do
  use Mix.Project

  @version "2.0.0-rc.3"
  def project do
    [
      app: :dilute,
      version: @version,
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "Dilute",
      docs: docs(),
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases()
    ]
  end

  def elixirc_paths(:test), do: ["test" | elixirc_paths(nil)]
  def elixirc_paths(:dev), do: ["test" | elixirc_paths(nil)]

  def elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, ">= 2.0.0", optional: true},
      # {:ecto_sql, "~> 3.0"},
      {:absinthe, "~> 1.4"},
      {:ex_doc, "~> 0.20", only: :dev},
      # {:myxql, ">= 0.0.0", only: :test}
      {:mariaex, "~> 0.8.0", only: [:dev, :test]}
    ]
  end

  defp description() do
    "Absinthe integration based on Ecto schema"
  end

  defp docs do
    [
      main: "Dilute",
      source_ref: "v#{@version}",
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

  defp aliases() do
    [
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
