defmodule ExTemplateTest do
  use ExUnit.Case
  doctest ExTemplate

  test "greets the world" do
    assert ExTemplate.hello() == :world
  end
end
