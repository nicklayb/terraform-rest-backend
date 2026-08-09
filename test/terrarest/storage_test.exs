defmodule Terrarest.StorageTest do
  use Terrarest.TestCase

  alias Terrarest.Storage

  setup [:verify_on_exit!]

  describe "init/0" do
    test "calls provider's init" do
      mock(:init, fn options ->
        assert options == configured_options()
        :ok
      end)

      assert :ok == Storage.init()
    end
  end

  describe "read/0" do
    test "calls provider's read" do
      mock(:read, fn options ->
        assert options == configured_options()
        :ok
      end)

      assert :ok == Storage.read()
    end
  end

  describe "unlock/0" do
    test "calls provider's unlock" do
      mock(:unlock, fn options ->
        assert options == configured_options()
        :ok
      end)

      assert :ok == Storage.unlock()
    end
  end

  describe "lock/1" do
    test "calls provider's lock only if unlocked" do
      expected_key = :key

      mock(:lock, fn key, options ->
        assert key == expected_key
        assert options == configured_options()
        :ok
      end)

      mock(:check_lock, fn options ->
        assert options == configured_options()

        :unlocked
      end)

      assert :ok == Storage.lock(expected_key)
    end

    test "fails to calls provider's lock only if locked" do
      expected_key = :key

      mock(:check_lock, fn options ->
        assert options == configured_options()

        {:locked, %{"ID" => "id"}}
      end)

      assert {:error, {:locked, %{"ID" => "id"}}} == Storage.lock(expected_key)
    end
  end

  describe "store/2" do
    test "calls provider's store safely if locked by same id only" do
      expected_content = "something"
      id = "id"

      mock(:store, [count: 1], fn content, options ->
        assert content == expected_content
        assert options == configured_options()
        :ok
      end)

      mock(:check_lock, [count: 2], fn options ->
        assert options == configured_options()
        {:locked, %{"ID" => id}}
      end)

      assert :ok == Storage.store(expected_content, id)
      assert {:error, {:locked, %{"ID" => ^id}}} = Storage.store(expected_content, "bad id")
    end

    test "calls provider's store safely if unlocked" do
      expected_content = "something"

      mock(:store, fn content, options ->
        assert content == expected_content
        assert options == configured_options()
        :ok
      end)

      mock(:check_lock, fn options ->
        assert options == configured_options()
        :unlocked
      end)

      assert :ok == Storage.store(expected_content, "id")
    end
  end

  defp configured_options do
    {_, options} = Application.fetch_env!(:terrarest, Terrarest.Storage)[:provider]
    options
  end
end
