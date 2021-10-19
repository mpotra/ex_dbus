defmodule ExDbus.MixProject do
  use Mix.Project

  @source_url "https://github.com/mpotra/ex_dbus"

  def project do
    [
      app: :ex_dbus,
      version: "0.1.1",
      elixir: ">= 1.11.3",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      source_url: @source_url,
      description: "Elixir implementation of D-Bus",
      package: package(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :dbus]
    ]
  end

  defp elixirc_paths(:dev), do: ["lib", "examples"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dbus, "~> 0.8.0"},
      {:saxy, "~> 1.4.0"},

      # Development dialyzer
      {:dialyxir, "~> 1.1.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Mihai Potra"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib LICENSE.md mix.exs README.md)
    ]
  end
end
