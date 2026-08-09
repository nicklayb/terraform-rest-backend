defmodule Terrarest.TestCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Terrarest.TestCase
      require Mox
      import Mox, only: [set_mox_global: 1, verify_on_exit!: 1]
      import Terrarest.MockConfig
    end
  end

  def mock(function, options \\ [], body) do
    count = Keyword.get(options, :count, 1)
    Mox.expect(Terrarest.MockStorage, function, count, body)
  end
end
