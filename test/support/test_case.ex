defmodule Terrarest.TestCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Terrarest.TestCase
      require Mox
      import Mox, only: [verify_on_exit!: 1]
    end
  end
end
