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
  repo: Replicator.Repo,
  mode: :slave,
  upstream_url: "http://localhost:5000/replog",
  sync_interval: 60 * 1000, # 1 minute
  schema_renames: %{},
  batch_size: 1000,
  cleanup_interval_ms: 1000 * 60 * 60 * 24, # Run cleanup each day
  cleanup_keep_s: 60 * 60 * 24 * 30 # Keep replogs for last month
