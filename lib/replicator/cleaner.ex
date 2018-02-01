defmodule Replicator.Cleaner do
  use GenServer

  require Logger

  import Ecto.Query

  alias Replicator.LastAppliedRepLog
  alias Replicator.RepLog
  alias Replicator.Repo

  alias Replicator.Utils

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    state = %{
      interval: Application.get_env(:replicator, :cleanup_interval_ms),
      keep: Application.get_env(:replicator, :cleanup_keep_s),
    }

    Logger.info "Starting Replicator Cleaner: state=#{inspect state} opts=#{inspect opts}"

    schedule_next(state)

    {:ok, state}
  end

  def handle_info(:do_work, state) do
    do_work(state)
    schedule_next(state)
    {:noreply, state}
  end

  defp schedule_next(%{interval: interval}) do
    Process.send_after(self(), :do_work, interval)
  end

  defp do_work(%{keep: keep}) do
    threshold = DateTime.utc_now()
                |> DateTime.to_unix()
                |> Kernel.-(keep)
                |> DateTime.from_unix!()

    result = from(rl in RepLog, where: rl.inserted_at < ^threshold) |> Repo.delete_all()
    Utils.run_callback :on_cleanup, result
  end
end
