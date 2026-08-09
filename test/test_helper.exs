ExUnit.start()

Application.ensure_all_started([:mox])

Mox.defmock(Terrarest.MockStorage, for: Terrarest.Storage)

Application.put_env(:terrarest, Terrarest.Storage,
  provider: {Terrarest.MockStorage, [option: :value]}
)
