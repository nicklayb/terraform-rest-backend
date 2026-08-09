defmodule Terrarest.Storage do
  @moduledoc """
  Storage system for persisting the `tfstate` files.
  """
  @type error :: {:error, any()}
  @type options :: Keyword.t()

  @callback init(options()) :: :ok | error()
  @callback read(options()) :: {:ok, String.t()} | error()
  @callback store(String.t(), options()) :: :ok | error()
  @callback lock(id :: String.t(), options()) :: :ok | error()
  @callback unlock(options()) :: :ok | error()
  @callback check_lock(options()) :: {:locked, String.t()} | :unlocked

  @doc "Initializes storage"
  @spec init() :: :ok | error()
  def init do
    {provider, options} = provider()
    provider.init(options)
  end

  @doc "Reads from the storage"
  @spec read() :: {:ok, String.t()} | error()
  def read do
    {provider, options} = provider()
    provider.read(options)
  end

  @doc "Unlocks the storage"
  @spec unlock() :: :ok | error()
  def unlock do
    {provider, options} = provider()
    provider.unlock(options)
  end

  @doc "Locks storage with given payload"
  @spec lock(String.t()) :: :ok | error()
  def lock(id) do
    ensure_unlocked(fn provider, options ->
      provider.lock(id, options)
    end)
  end

  @doc "Stores content from session id as lock check"
  @spec store(String.t(), String.t()) :: :ok | error()
  def store(content, current_id) do
    ensure_unlocked(current_id, fn provider, options ->
      provider.store(content, options)
    end)
  end

  defp ensure_unlocked(current_id \\ nil, function) do
    {provider, options} = provider()

    case provider.check_lock(options) do
      {:locked, %{"ID" => id}} when id == current_id ->
        function.(provider, options)

      {:locked, info} ->
        {:error, {:locked, info}}

      :unlocked ->
        function.(provider, options)
    end
  end

  defp provider do
    :terrarest
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.fetch!(:provider)
  end
end
