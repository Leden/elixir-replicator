# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :replicator, Replicator.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "replicator_repo",
  username: "user",
  password: "pass",
  hostname: "localhost"

config :replicator,
  ecto_repos: [Replicator.Repo],
  mode: :slave,
  upstream_url: "http://localhost:5000/replog",
  sync_interval: 60 * 1000 # 1 minute
