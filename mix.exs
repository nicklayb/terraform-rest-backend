defmodule MusicBoss.MixProject do
  use Mix.Project

  def project do
    [
      app: :music_boss,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {MusicBoss.Application, []}
    ]
  end

  defp deps do
    [
      {:box, git: "https://github.com/nicklayb/box_ex.git", tag: "0.17.6"},
      {:bandit, "~> 1.12"},
      {:plug, "~>1.20.3"},
      {:req, "~> 0.7.2"},
      {:oapi_generator, "~> 0.4.0", only: :dev, runtime: false}
    ]
  end
end
