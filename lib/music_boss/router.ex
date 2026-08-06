defmodule MusicBoss.Router do
  use Plug.Router

  plug(Plug.Logger)
  plug(:match)
  plug(:dispatch)

  get("/recommendations", to: MusicBoss.Router.Recommendations)

  match(_) do
    send_resp(conn, 404, "Not Found")
  end

  def child_spec(args) do
    Bandit.child_spec(
      Keyword.merge(
        [
          plug: __MODULE__,
          port: config(:port)
        ],
        args
      )
    )
  end

  defp config(key) do
    :music_boss
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.fetch!(key)
  end
end
