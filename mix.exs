defmodule ExDbus.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_dbus,
      version: "0.1.0",
      elixir: "~> 1.11.3",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
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
      {:dbus, git: "https://github.com/mpotra/erlang-dbus"},
      # {:dbus, path: "../erlang-dbus"},
      {:saxy, "~> 1.4.0"},

      # Development dialyzer
      {:dialyxir, "~> 1.1.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Mihai Potra"],
      licenses: ["MIT"],
      links: %{github: "mpotra/ex_dbus"},
      files: ~w(lib LICENSE.md mix.exs README.md)
    ]
  end
end
