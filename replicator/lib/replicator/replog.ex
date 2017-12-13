defmodule Replicator.RepLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "replicator_replog" do
    field :entity, :string
    field :operation, :string
    field :previous, :map
    field :current, :map
    timestamps()
  end

  def changeset(replog, params \\ %{}) do
    replog
    |> cast(params, [:id, :entity, :operation, :previous, :current])
    |> validate_required([:entity, :operation])
  end
end
