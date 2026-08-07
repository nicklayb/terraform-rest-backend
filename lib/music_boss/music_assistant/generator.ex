defmodule MusicBoss.MusicAssistant.Generator do
  defmacro __using__(options) do
    quote do
      import MusicBoss.MusicAssistant.Generator

      @client Keyword.fetch!(unquote(options), :client)
    end
  end

  defmacro commands(commands) do
    Enum.map(commands, fn command_name ->
      name =
        command_name
        |> String.split("/")
        |> Enum.join("_")
        |> String.to_atom()

      quote do
        def unquote(name)(args, options \\ []) do
          @client.rpc(unquote(command_name), args, options)
        end
      end
    end)
  end
end
