defmodule ExampleprojectTest do
  use ExUnit.Case
  doctest Exampleproject

  test "greets the world" do
    assert Exampleproject.hello() == :world
  end
end
