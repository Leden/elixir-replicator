defmodule Replicator.Repo.Migrations.AddReplog do
  use Ecto.Migration

  def change do
    create table("replicator_replog") do
      add :entity, :string
      add :operation, :string
      add :previous, :map
      add :current, :map
      timestamps()
    end

  end
end
