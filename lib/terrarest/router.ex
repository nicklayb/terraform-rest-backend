defmodule Terrarest.Router do
  use Plug.Router

  plug(Plug.Logger)
  plug(:match)

  # Work around because Parsers matches only on POST, PATCH, PUT and DELETE
  plug(:stash_method, replace_with: "POST")

  plug(Plug.Parsers,
    parsers: [:urlencoded, :json],
    json_decoder: JSON
  )

  plug(:unstash_method)

  plug(:dispatch)

  match(_, to: Terrarest.Router.Handler)

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

  defp stash_method(%Plug.Conn{} = conn, options) do
    replace_with = Keyword.fetch!(options, :replace_with)

    conn
    |> assign(:__method__, conn.method)
    |> put_method(replace_with)
  end

  defp unstash_method(%Plug.Conn{} = conn, _) do
    put_method(conn, conn.assigns.__method__)
  end

  defp put_method(%Plug.Conn{} = conn, method) do
    %Plug.Conn{conn | method: method}
  end

  defp config(key) do
    :terrarest
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.fetch!(key)
  end
end
