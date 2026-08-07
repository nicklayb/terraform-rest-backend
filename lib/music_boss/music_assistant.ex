defmodule MusicBoss.MusicAssistant do
  use MusicBoss.MusicAssistant.Generator, client: MusicBoss.MusicAssistant.Client

  commands([
    "music/albums/library_items"
  ])
end
