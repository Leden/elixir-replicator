defmodule ReplicatorTest do
  use ExUnit.Case
  doctest Replicator

  test "greets the world" do
    assert Replicator.hello() == :world
  end
end
