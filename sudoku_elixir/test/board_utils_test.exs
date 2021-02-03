defmodule BoardUtilsTest do
  use ExUnit.Case
  doctest BoardUtils

  test "greets the world" do
    assert BoardUtils.hello() == :world
  end
end
