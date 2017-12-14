defmodule Replicator.LastAppliedRepLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "replicator_last_applied_replog" do
    field :last_id, :id
    timestamps()
  end

  def changeset(last_applied_replog, params \\ %{}) do
    last_applied_replog
    |> cast(params, [:last_id])
    |> validate_required([:last_id])
  end
end
