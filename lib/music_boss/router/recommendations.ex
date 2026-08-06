defmodule MusicBoss.Router.Recommendations do
  import Plug.Conn

  def init(_), do: :ok

  def call(%Plug.Conn{} = conn, _options) do
    send_resp(conn, 200, "OK")
  end
end
