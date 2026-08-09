defmodule Terrarest.Storage.Provider.File do
  @moduledoc """
  Provider that uses a physical file on disk to store the tfstate and 
  :persistent_term to manage locking
  """
  @behaviour Terrarest.Storage

  @impl Terrarest.Storage
  def init(options) do
    options
    |> Keyword.fetch!(:location)
    |> File.mkdir_p!()
  end

  @impl Terrarest.Storage
  def read(options) do
    options
    |> file_name()
    |> File.read()
  end

  @impl Terrarest.Storage
  def store(content, options) do
    backup_previous_state(options)

    options
    |> file_name()
    |> File.write(content)
  end

  @tfstate "terraform.tfstate"
  defp backup_previous_state(options) do
    file_name = file_name(options)

    if File.exists?(file_name) do
      new_path =
        options
        |> Keyword.fetch!(:location)
        |> Path.join(@tfstate <> ".backup")

      File.cp(file_name, new_path)
    end
  end

  defp file_name(options) do
    options
    |> Keyword.fetch!(:location)
    |> Path.join(@tfstate)
  end

  @impl Terrarest.Storage
  def lock(id, options) do
    options
    |> Keyword.fetch!(:lock_key)
    |> :persistent_term.put(id)

    :ok
  end

  @impl Terrarest.Storage
  def unlock(options) do
    options
    |> Keyword.fetch!(:lock_key)
    |> :persistent_term.erase()

    :ok
  end

  @impl Terrarest.Storage
  def check_lock(options) do
    state =
      options
      |> Keyword.fetch!(:lock_key)
      |> :persistent_term.get()

    case state do
      nil ->
        :unlocked

      other ->
        {:locked, other}
    end
  rescue
    _ ->
      :unlocked
  end
end
