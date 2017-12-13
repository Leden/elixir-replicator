defmodule Replicator.Client do
  use GenServer

  require Logger

  import Ecto.Query

  alias Replicator.LastAppliedRepLog
  alias Replicator.RepLog
  alias Replicator.Repo

  def start_link do
    GenServer.start_link(__MODULE__, %{})
  end

  def init do
    state = %{
      upstream_url: Application.get_env(:replicator, :upstream_url),
      sync_interval: Application.get_env(:replicator, :sync_interval),
    }

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

    case HTTPoison.get!(url) do
      %{status_code: 200, body: body} -> body |> Poison.decode!() |> save_replogs()
      %{status_code: status, body: body} ->
        # Something bad happened
        Logger.warn "Sync error while querying center: #{inspect status}, #{inspect body}"
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

  defp save_replogs([]), do: :ok

  defp save_replogs(replogs) when is_list(replogs) do
    Repo.transaction(fn ->
      replogs
      |> save_replogs(0)
      |> save_last_id()
    end)
  end

  defp save_replogs([], last_id), do: last_id

  defp save_replogs([replog | tail], last_id) do
    id = save_replog(replog)
    save_replogs(tail, Enum.max([id, last_id]))
  end

  defp save_replog(%RepLog{id: id, operation: "insert", schema: schema, current: current}) do
    schema
    |> String.to_existing_atom()
    |> struct(current)
    |> Repo.insert!()

    id
  end

  defp save_replog(%RepLog{id: id, operation: "update", schema: schema, current: current, previous: previous}) do
    schema
    |> String.to_existing_atom()
    |> struct(previous)
    |> schema.changeset(current)
    |> Repo.update!()

    id
  end

  defp save_replog(%RepLog{id: id, operation: "delete", schema: schema, previous: previous}) do
    schema
    |> String.to_existing_atom()
    |> struct(previous)
    |> Repo.delete!()

    id
  end

  defp save_last_id(id) do
    case Repo.one(LastAppliedRepLog) do
      nil ->
        %LastAppliedRepLog{last_id: id}
        |> Repo.insert!()

      replog ->
        replog
        |> LastAppliedRepLog.changeset(%{last_id: id})
        |> Repo.update!()
    end
  end

end