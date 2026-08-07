defmodule MusicBoss.Servers.Recommendations do
  use MusicBoss.Servers.Generator

  def handle_update(state) do
    Process.sleep(:timer.seconds(3))
    {:ok, %{}}
  end
end
