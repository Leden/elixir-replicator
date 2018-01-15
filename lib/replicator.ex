defmodule Replicator do
  @moduledoc """
  Documentation for Replicator.
  """

  alias Replicator.RepLog

  @callbacks Application.get_env(:replicator, :callbacks, Replicator.DummyCallbacks)
  @repo Application.get_env(:replicator, :repo)

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
    |> callback(:insert)
    schema
  end

  @doc """
  TODO
  """
  def log_update(%module{} = previous_schema, %module{} = current_schema) do
    if previous_schema != current_schema do
      insert_replog(%{
        schema: Atom.to_string(module),
        operation: "update",
        previous: dehydrate(previous_schema),
        current: dehydrate(current_schema),
      })
      |> callback(:update)
    end
    current_schema
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
    |> callback(:delete)
    schema
  end

  @doc """
  TODO
  """
  def get_replog(last_id) do
    import Ecto.Query

    @repo.all(
      from r in RepLog,
      order_by: r.id,
      where: fragment("? BETWEEN ? AND ? + 1000", r.id, ^last_id, ^last_id)
    )
  end

  defp insert_replog(params) do
    %RepLog{}
    |> RepLog.changeset(params)
    |> @repo.insert!()
  end

  defp dehydrate(%module{} = schema) do
    schema
    |> Map.from_struct()
    |> Map.take(module.__schema__(:fields))
  end

  defp callback(replog, operation) do
    fun = String.to_existing_atom("on_" <> Atom.to_string(operation))
    args = [replog]

    apply @callbacks, fun, args
  end
end
