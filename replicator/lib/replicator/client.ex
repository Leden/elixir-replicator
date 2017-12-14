defmodule Replicator.Client do
  use GenServer

  require Logger

  import Ecto.Query

  alias Replicator.LastAppliedRepLog
  alias Replicator.RepLog
  alias Replicator.Repo

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
      {:ok, %{status_code: 200, body: body}} -> body |> Poison.decode!() |> apply_all_replogs(last_id)
      {:ok, %{status_code: status, body: body}} ->
        # Something bad happened
        Logger.warn "Sync error while querying center: #{inspect status}, #{inspect body}"
      {:error, reason} ->
        # Could not connect at all
        Logger.warn "Sync error while querying center: #{inspect reason}"
    end
  end

  defp get_last_id do
    case Repo.one(LastAppliedRepLog) do
      nil ->
        # First sync ever: assume DB was dumped from Center, take latest RepLog ID.
        # If RepLog is empty, we're in trouble (do not know the current state of DB) and must die on the spot.
        %{id: last_id} = RepLog |> last(:id) |> Repo.one()
        last_id

      %{last_id: last_id} -> last_id
    end
  end

  defp prepare_url(upstream_url, last_id) do
    upstream_url
    |> URI.parse()
    |> Map.put(:query, URI.encode_query(%{last_id: last_id}))
    |> URI.to_string()
  end

  defp apply_all_replogs(replogs, last_id) do
    Repo.transaction(fn ->
      replogs
      |> save_replogs(last_id)
      |> save_last_id()
    end)
  end

  defp save_replogs([], last_id), do: last_id

  defp save_replogs([replog | tail], last_id) do
    id = case replog do
      %{id: id} when id > last_id ->
        replog |> to_ecto_schema(RepLog) |> save_replog()
        id

      _ -> last_id
    end

    save_replogs(tail, id)
  end

  defp save_replog(%RepLog{operation: "insert", schema: schema, current: current}) do
    current
    |> to_ecto_schema(schema)
    |> Repo.insert!()
  end

  defp save_replog(%RepLog{operation: "update", schema: schema, current: current, previous: previous}) do
    module = schema |> String.to_existing_atom()

    previous
    |> to_ecto_schema(schema)
    |> module.changeset(current)
    |> Repo.update!()
  end

  defp save_replog(%RepLog{operation: "delete", schema: schema, previous: previous}) do
    previous
    |> to_ecto_schema(schema)
    |> Repo.delete!()
  end

  defp save_last_id(id) do
    case Repo.one(LastAppliedRepLog) do
      nil ->
        %LastAppliedRepLog{id: 1, last_id: id}
        |> Repo.insert!()

      replog ->
        replog
        |> LastAppliedRepLog.changeset(%{last_id: id})
        |> Repo.update!()
    end
  end

  defp to_ecto_schema(data, schema) when is_binary(schema) do
    to_ecto_schema(data, String.to_existing_atom(schema))
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
end
