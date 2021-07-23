defmodule ExDbusTest do
  use ExUnit.Case
  doctest ExDbus

  test "greets the world" do
    assert ExDbus.hello() == :world
  end
end
