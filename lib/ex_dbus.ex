defmodule ExDBus do
  @moduledoc """
  Documentation for `ExDbus`.
  """

  use Application

  @doc """
  The application entry-point.
  """
  @impl true
  def start(_type, _args) do
    IO.puts("Starting ExDBus Application")

    children = [
      # {MyIcon, name: MyIcon}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ExDBus.Supervisor]

    Supervisor.start_link(children, opts)
    |> IO.inspect(label: "ExDBus Supervisor started")
  end
end
