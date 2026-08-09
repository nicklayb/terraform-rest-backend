defmodule Terrarest.Router.Handler do
  import Plug.Conn

  require Logger

  def init(_), do: :ok
  @default %{version: 1}
  def call(%Plug.Conn{method: "GET"} = conn, _options) do
    info("Reading")

    json =
      case Terrarest.Storage.read() do
        {:ok, content} -> content
        _ -> @default
      end

    json(conn, json)
  end

  def call(%Plug.Conn{method: "LOCK"} = conn, _options) do
    id = conn.body_params["ID"]

    info("Locking", operation: conn.body_params["Operation"], id: id)

    case Terrarest.Storage.lock(conn.body_params) do
      :ok ->
        send_resp(conn, 200, "OK")

      {:error, error} ->
        error(inspect(error), id: id)
        handle_error(conn, error)
    end
  end

  def call(%Plug.Conn{method: "UNLOCK"} = conn, _options) do
    id = conn.body_params["ID"]
    info("Unlocking", operation: conn.body_params["Operation"], id: id)

    case Terrarest.Storage.unlock() do
      :ok ->
        send_resp(conn, 200, "OK")

      {:error, error} ->
        error(inspect(error), id: id)
        handle_error(conn, error)
    end
  end

  def call(%Plug.Conn{method: "POST", query_params: %{"ID" => current_id}} = conn, _options) do
    info("Updating", id: current_id)
    json = JSON.encode!(conn.body_params)

    case Terrarest.Storage.store(json, current_id) do
      :ok ->
        send_resp(conn, 200, "OK")

      {:error, error} ->
        error(inspect(error), id: current_id)
        handle_error(conn, error)
    end
  end

  defp handle_error(%Plug.Conn{} = conn, error) do
    case error do
      {:locked, info} ->
        json(conn, 423, info)

      _error ->
        send_resp(conn, 400, "Bad request")
    end
  end

  defp json(conn, status \\ 200, json)

  defp json(%Plug.Conn{} = conn, status, json) when not is_binary(json) do
    json(conn, status, JSON.encode!(json))
  end

  defp json(%Plug.Conn{} = conn, status, json) do
    conn
    |> put_resp_header("content-type", "application/json")
    |> send_resp(status, json)
  end

  defp error(message, attributes) do
    attributes
    |> build_message(message)
    |> Logger.info()
  end

  defp info(message, attributes \\ []) do
    attributes
    |> build_message(message)
    |> Logger.info()
  end

  defp build_message(attributes, message) do
    attributes = Enum.map(attributes, fn {key, value} -> "[#{key}: #{value}]" end)
    content = ["[#{inspect(__MODULE__)}]" | attributes]
    message = if message == "", do: "", else: " " <> message
    Enum.join(content, " ") <> message
  end
end
