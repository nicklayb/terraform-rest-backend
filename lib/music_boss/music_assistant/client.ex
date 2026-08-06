defmodule MusicBoss.MusicAssistant.Client do
  def music_albums_library_items do
    rpc("music/albums/library_items", %{})
  end

  defp rpc(command, args, options \\ []) do
    options =
      Keyword.merge(options,
        body: %{command: command, args: Map.put(args, :kwargs, %{"_comment" => "Dragon"})}
      )

    call(:post, "/api", options)
  end

  defp call(method, path, options) do
    Req.request(
      method: method,
      base_url: config(:host),
      json: Keyword.get(options, :body),
      url: path,
      headers: headers(options)
    )
  end

  defp headers(options) do
    incoming_headers = Keyword.get(options, :headers, [])

    [
      {"Authorization", "Bearer #{config(:token)}"}
    ] ++ incoming_headers
  end

  defp config(key) do
    :music_boss
    |> Application.fetch_env!(MusicBoss.MusicAssistant)
    |> Keyword.fetch!(key)
  end
end
