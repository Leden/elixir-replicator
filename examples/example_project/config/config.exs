# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config


config :example_project,
       ecto_repos: [ExampleProject.Repo]

config :example_project, ExampleProject.Repo,
       adapter: Ecto.Adapters.Postgres,
       database: System.get_env("DATABASE") || "example_project_repo",
       username: "user",
       password: "pass",
       hostname: "postgres"


config :replicator,
  repo: Replicator.Repo,
  mode: (case System.get_env("REPLICATION_MODE") do
           "slave" -> :slave
           _ -> :master
         end),
  upstream_url: "http://localhost:5000/replog",
  sync_interval: 60 * 1000, # 1 minute
  callbacks: ExampleProject.ReplicatorCallbacks

config :replicator, Replicator.Repo,
       adapter: Ecto.Adapters.Postgres,
       database: System.get_env("DATABASE") || "example_project_repo",
       username: "user",
       password: "pass",
       hostname: "postgres"
