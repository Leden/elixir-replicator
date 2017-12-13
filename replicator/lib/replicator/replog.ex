defmodule Replicator.RepLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "replicator_replog" do
    field :schema, :string
    field :operation, :string
    field :previous, :map
    field :current, :map
    timestamps()
  end

  def changeset(replog, params \\ %{}) do
    replog
    |> cast(params, [:id, :schema, :operation, :previous, :current])
    |> validate_required([:schema, :operation])
  end
end
