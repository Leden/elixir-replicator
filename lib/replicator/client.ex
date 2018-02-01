defmodule Replicator.Client do
  use GenServer

  require Logger

  import Ecto.Query

  alias Replicator.LastAppliedRepLog
  alias Replicator.RepLog
  alias Replicator.Utils

  @repo Application.get_env(:replicator, :repo)

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    state = %{
      upstream_url: Application.get_env(:replicator, :upstream_url),
      sync_interval: Application.get_env(:replicator, :sync_interval),
    }

    Logger.info "Starting Replicator Client: state=#{inspect state} opts=#{inspect opts}"

    schedule_next(state)

    {:ok, state}
  end

  def handle_info(:sync, state) do
    sync(state)
    schedule_next(state)
    {:noreply, state}
  end

  defp schedule_next(%{sync_interval: sync_interval}) do
    Process.send_after(self(), :sync, sync_interval)
  end

  defp sync(%{upstream_url: upstream_url}) do
    last_id = get_last_id()
    url = prepare_url(upstream_url, last_id)

    Logger.info "last_id=#{inspect last_id} url=#{inspect url}"

    case HTTPoison.get(url) do
      {:ok, %{status_code: 200, body: body}} ->
        body
        |> Poison.decode!()
        |> apply_all_replogs(last_id)
        |> callback()

      {:ok, %{status_code: status, body: body}} ->
        # Something bad happened
        Logger.warn "Sync error while querying center: #{inspect status}, #{inspect body}"
      {:error, reason} ->
        # Could not connect at all
        Logger.warn "Sync error while querying center: #{inspect reason}"
    end
  end

  defp get_last_id do
    case @repo.one(LastAppliedRepLog) do
      %{last_id: last_id} -> last_id

      nil ->
        # First sync ever: assume DB was dumped from Center, take latest RepLog ID.
        # If RepLog is empty, we're most likely in dev with empty DB, so let's start from the beginning.
        RepLog
        |> last(:id)
        |> @repo.one()
        |> case do
          %{id: last_id} -> last_id
          nil -> 0
        end
    end
  end

  defp prepare_url(upstream_url, last_id) do
    upstream_url
    |> URI.parse()
    |> Map.put(:query, URI.encode_query(%{last_id: last_id}))
    |> URI.to_string()
  end

  defp apply_all_replogs(replogs, last_id) do
    @repo.transaction(fn ->
      replogs
      |> save_replogs(last_id)
      |> save_last_id()
    end)
  end

  defp save_replogs([], last_id), do: last_id

  defp save_replogs([replog | tail], last_id) do
    id = case replog do
      %{"id" => id} when id > last_id ->
        replog |> to_ecto_schema(RepLog) |> save_replog()
        id

      _ ->
        Logger.debug "Skipping #{inspect replog} because its id is smaller than #{last_id}"
        last_id
    end

    save_replogs(tail, id)
  end

  defp save_replog(%RepLog{operation: "insert", schema: schema, current: current}) do
    current
    |> to_ecto_schema(schema)
    |> @repo.insert!()
  end

  defp save_replog(%RepLog{operation: "update", schema: schema, current: current, previous: previous}) do
    module = schema
             |> get_actual_schema()
             |> String.to_existing_atom()

    previous
    |> to_ecto_schema(schema)
    |> module.changeset(current)
    |> @repo.update!()
  end

  defp save_replog(%RepLog{operation: "delete", schema: schema, previous: previous}) do
    previous
    |> to_ecto_schema(schema)
    |> @repo.delete!()
  end

  defp save_last_id(id) do
    case @repo.one(LastAppliedRepLog) do
      nil ->
        %LastAppliedRepLog{id: 1, last_id: id}
        |> @repo.insert!()

      replog ->
        replog
        |> LastAppliedRepLog.changeset(%{last_id: id})
        |> @repo.update!()
    end
  end

  defp to_ecto_schema(data, schema) when is_binary(schema) do
    module = schema
             |> get_actual_schema()
             |> String.to_existing_atom()
    to_ecto_schema(data, module)
  end
  defp to_ecto_schema(data, schema) when is_atom(schema) do
    changeset = Ecto.Changeset.cast(struct(schema), data, schema.__schema__(:fields))

    Logger.debug """
    to_ecto_schema:
      * data = #{inspect data}
      * schema = #{inspect schema}
      * changeset = #{inspect changeset}
    """

    Enum.reduce schema.__schema__(:fields), struct(schema), fn field, acc ->
      %{acc | field => Ecto.Changeset.get_field(changeset, field)}
    end
  end

  defp callback({:ok, %LastAppliedRepLog{} = last_applied_replog}) do
    Utils.run_callback :on_replication_success, last_applied_replog
  end
  defp callback(_) do :ok end

  defp get_actual_schema(schema) do
    Application.get_env(:replicator, :schema_renames)
    |> Map.get(schema, schema)
  end
end
