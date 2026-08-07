import Config

config(:terrarest, Terrarest.Router, port: Box.Config.get("PORT", default: "4000"))

{provider, provider_options} =
  case Box.Config.get("STORAGE_PROVIDER", default: "file") do
    "file" ->
      {Terrarest.Storage.Provider.File, [location: Box.Config.get!("STORAGE_FILE_LOCATION")]}
  end

config(:terrarest, Terrarest.Storage, provider: {provider, provider_options})
