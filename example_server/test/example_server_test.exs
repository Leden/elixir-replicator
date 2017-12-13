defmodule ExampleServerTest do
  use ExUnit.Case
  doctest ExampleServer

  test "greets the world" do
    assert ExampleServer.hello() == :world
  end
end
