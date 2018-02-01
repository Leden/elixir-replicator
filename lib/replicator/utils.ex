defmodule Replicator.Utils do
  @callbacks Application.get_env(:replicator, :callbacks, Replicator.DummyCallbacks)

  def defined?(module, function, arity) do
    Enum.member? module.__info__(:functions), {function, arity}
  end

  def run_callback(name, arg) do
    if defined? @callbacks, name, 1 do
      apply @callbacks, name, [arg]
    end
  end
end
