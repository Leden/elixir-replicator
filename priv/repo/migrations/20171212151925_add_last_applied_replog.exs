defmodule Replicator.Repo.Migrations.AddLastAppliedReplog do
  use Ecto.Migration

  def change do
    create table("replicator_last_applied_replog") do
      add :last_id, :bigint, null: false
      timestamps()
    end
  end
end
