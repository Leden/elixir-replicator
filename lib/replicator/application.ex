defmodule Replicator.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Replicator.Supervisor]
    Supervisor.start_link(children(), opts)
  end

  def children do
    children = Application.get_env(:replicator, :mode) |> children()
    [Replicator.Repo | children]
  end

  def children(:slave), do: [Replicator.Client]
  def children(:master), do: [Replicator.Cleaner]
  def children(_), do: []
end
