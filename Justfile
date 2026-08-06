open_api_spec := env('MUSIC_ASSISTANT_HOST') + "/api-docs/openapi.json"

server:
  iex -S mixs

dump-openapi-spec:
  mix api.gen default 
