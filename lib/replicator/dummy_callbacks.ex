defmodule Replicator.DummyCallbacks do
  @moduledoc false

  def on_insert(_replog), do: :ok
  def on_update(_replog), do: :ok
  def on_delete(_replog), do: :ok
  def on_replication_success(_last_applied_replog), do: :ok
  def on_cleanup(_cleanup_result), do: :ok

end
