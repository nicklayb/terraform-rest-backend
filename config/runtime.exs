import Config

config(:music_boss, MusicBoss.Router, port: Box.Config.get("PORT", default: "4000"))

config(:music_boss, MusicBoss.MusicAssistant,
  host: Box.Config.get("MUSIC_ASSISTANT_HOST"),
  token: Box.Config.get("MUSIC_ASSISTANT_TOKEN")
)
