defmodule Terrarest.Router.HandlerTest do
  use Terrarest.TestCase, async: false

  alias Terrarest.Router.Handler

  setup [:init_conn, :verify_on_exit!]

  @content ~s({"version": 5, "something_else": "data"})

  describe "GET /" do
    test "retrieves default when storage is empty", %{conn: conn} do
      mock(:read, fn _ -> {:error, :enoent} end)

      assert %Plug.Conn{
               resp_body: ~s({"version":1}),
               resp_headers: resp_headers,
               status: 200,
               halted: false,
               method: "GET"
             } =
               call_handler(conn)

      assert {"content-type", "application/json"} in resp_headers
    end

    test "retrieves what's in the storage", %{conn: conn} do
      mock(:read, fn _ -> {:ok, @content} end)

      assert %Plug.Conn{
               resp_body: @content,
               resp_headers: resp_headers,
               status: 200,
               halted: false,
               method: "GET"
             } =
               call_handler(conn)

      assert {"content-type", "application/json"} in resp_headers
    end
  end

  describe "LOCK /" do
    @params %{"ID" => "id", "Operation" => "operation"}
    @tag method: "LOCK", body_params: @params
    test "locks with data successfully when unlocked", %{conn: conn} do
      mock(:lock, fn @params, _ -> :ok end)
      mock(:check_lock, fn _ -> :unlocked end)

      assert %Plug.Conn{status: 200, halted: false, resp_body: "OK", method: "LOCK"} =
               call_handler(conn)
    end

    @tag method: "LOCK", body_params: @params
    test "doesn't lock if already locked", %{conn: conn} do
      mock(:check_lock, fn _ -> {:locked, @params} end)

      assert %Plug.Conn{status: 423, halted: false, resp_body: response_body, method: "LOCK"} =
               call_handler(conn)

      assert JSON.decode!(response_body) == @params
    end
  end

  describe "UNLOCK /" do
    @params %{"ID" => "id", "Operation" => "operation"}
    @tag method: "UNLOCK", body_params: @params
    test "unlocks no matter what's in the store", %{conn: conn} do
      mock(:unlock, fn _ -> :ok end)

      assert %Plug.Conn{status: 200, halted: false, resp_body: "OK", method: "UNLOCK"} =
               call_handler(conn)
    end
  end

  describe "POST /" do
    @id "id"
    @params %{"ID" => @id}
    @body_params %{version: 6}
    @body_params_json JSON.encode!(@body_params)
    @tag method: "POST", query_params: @params, body_params: @body_params
    test "stores if storage is unlocked", %{conn: conn} do
      mock(:check_lock, fn _ -> :unlocked end)
      mock(:store, fn @body_params_json, _ -> :ok end)

      assert %Plug.Conn{status: 200, halted: false, resp_body: "OK", method: "POST"} =
               call_handler(conn)
    end

    @tag method: "POST", query_params: @params, body_params: @body_params
    test "stores if storage is locked by same user", %{conn: conn} do
      mock(:check_lock, fn _ -> {:locked, @params} end)
      mock(:store, fn @body_params_json, _ -> :ok end)

      assert %Plug.Conn{status: 200, halted: false, resp_body: "OK", method: "POST"} =
               call_handler(conn)
    end

    @bad_params %{"ID" => @id <> "other"}
    @tag method: "POST", query_params: @params, body_params: @body_params
    test "fails if storage is locked by another user", %{conn: conn} do
      other_id = "another_id"
      mock(:check_lock, fn _ -> {:locked, @bad_params} end)

      assert other_id != @id

      assert %Plug.Conn{status: 423, halted: false, resp_body: resp_body, method: "POST"} =
               call_handler(conn)

      assert JSON.decode!(resp_body) == @bad_params
    end
  end

  defp init_conn(context) do
    method = Map.get(context, :method, :get)
    %Plug.Conn{} = conn = Plug.Test.conn(method, "/")

    conn =
      case Map.get(context, :body_params) do
        %{} = params -> %Plug.Conn{conn | body_params: params}
        _ -> conn
      end

    conn =
      case Map.get(context, :query_params) do
        %{} = params -> %Plug.Conn{conn | query_params: params}
        _ -> conn
      end

    [conn: conn]
  end

  defp call_handler(conn) do
    Handler.call(conn, Handler.init([]))
  end
end
