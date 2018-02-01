defmodule ExampleProject.ReplicatorCallbacks do
  require Logger

  def on_insert(replog) do
    Logger.info "INSERT happened with #{inspect replog}"
  end

  def on_update(replog) do
    Logger.info "UPDATE happened with #{inspect replog}"
  end

  def on_delete(replog) do
    Logger.info "DELETE happened with #{inspect replog}"
  end

  def on_replication_success(last_applied_replog) do
    Logger.info "REPLICATION success with #{inspect last_applied_replog}"
  end

  def on_cleanup(result) do
    Logger.info "CLEANUP success with #{inspect result}"
  end
end
