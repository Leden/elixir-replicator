defmodule ExampleProject.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    port = case System.get_env("HTTP_PORT") do
      nil -> 5000
      smth -> String.to_integer(smth)
    end

    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: ExampleProject.Worker.start_link(arg)
      # {ExampleProject.Worker, arg},
      Plug.Adapters.Cowboy.child_spec(
        :http, ExampleProject.Router, [], [port: port]
      ),
      ExampleProject.Repo,
    ]

    children = case System.get_env("REPLICATION_MODE") do
      "slave" -> [ Replicator.Client | children ]
      _ -> children
    end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ExampleProject.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
