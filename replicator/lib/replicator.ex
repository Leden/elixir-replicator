defmodule Replicator do
  @moduledoc """
  Documentation for Replicator.
  """

  alias Replicator.RepLog
  alias Replicator.Repo

  import Ecto.Query

  @doc """
  TODO
  """
  def log_insert(%module{} = schema) do
    insert_replog(%{
      schema: Atom.to_string(module),
      operation: "insert",
      previous: nil,
      current: dehydrate(schema),
    })
  end

  @doc """
  TODO
  """
  def log_update(%module{} = previous_schema, %module{} = current_schema) do
    insert_replog(%{
      schema: Atom.to_string(module),
      operation: "update",
      previous: dehydrate(previous_schema),
      current: dehydrate(current_schema),
    })
  end

  @doc """
  TODO
  """
  def log_delete(%module{} = schema) do
    insert_replog(%{
      schema: Atom.to_string(module),
      operation: "delete",
      previous: dehydrate(schema),
      current: nil,
    })
  end

  @doc """
  TODO
  """
  def get_replog(last_id) do
    Repo.all(
      from r in RepLog,
      order_by: r.id,
      where: fragment("? BETWEEN ? AND ? + 1000", r.id, ^last_id, ^last_id)
    )
  end

  defp insert_replog(params) do
    %RepLog{}
    |> RepLog.changeset(params)
    |> Repo.insert!()
  end

  defp dehydrate(%module{} = schema) do
    schema
    |> Map.from_struct()
    |> Map.take(module.__schema__(:fields))
  end
end