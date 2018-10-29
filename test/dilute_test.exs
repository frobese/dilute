defmodule DiluteTest do
  use ExUnit.Case
  doctest Dilute

  test "greets the world" do
    assert Dilute.hello() == :world
  end
end
