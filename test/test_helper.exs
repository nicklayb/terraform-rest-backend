ExUnit.start()

Mox.defmock(Terrarest.MockStorage, for: Terrarest.Storage)

Application.put_env(:terrarest, Terrarest.Storage, provider: {Terrarest.MockStorage, []})
