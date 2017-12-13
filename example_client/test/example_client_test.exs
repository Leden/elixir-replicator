defmodule ExampleClientTest do
  use ExUnit.Case
  doctest ExampleClient

  test "greets the world" do
    assert ExampleClient.hello() == :world
  end
end
