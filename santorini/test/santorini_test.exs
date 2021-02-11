defmodule SantoriniTest do
  use ExUnit.Case
  doctest Santorini

  test "greets the world" do
    assert Santorini.hello() == :world
  end
end
