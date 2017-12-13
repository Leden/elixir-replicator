defmodule Replicator do
  @moduledoc """
  Documentation for Replicator.
  """

  alias Replicator.RepLog
  alias Replicator.Repo

  @doc """
  TODO
  """
  def log_insert(%mod{} = entity) do
    insert_replog(%{
      entity: mod.__schema__(:source),
      operation: "insert",
      previous: nil,
      current: entity |> dehydrate(),
    })
  end

  @doc """
  TODO
  """
  def log_update(%mod{} = previous_entity, %mod{} = current_entity) do
    insert_replog(%{
      entity: mod.__schema__(:source),
      operation: "update",
      previous: previous_entity |> dehydrate(),
      current: current_entity |> dehydrate(),
    })
  end

  @doc """
  TODO
  """
  def log_delete(%mod{} = entity) do
    insert_replog(%{
      entity: mod.__schema__(:source),
      operation: "delete",
      previous: entity |> dehydrate(),
      current: nil,
    })
  end

  defp insert_replog(params) do
    %RepLog{}
    |> RepLog.changeset(params)
    |> Repo.insert!()
  end

  defp dehydrate(%mod{} = entity) do
    entity
    |> Map.from_struct()
    |> Map.take(mod.__schema__(:fields))
  end
end
