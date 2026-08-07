defmodule Terrarest.Storage.Provider.File do
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

  @key :terraform_lock

  @impl Terrarest.Storage
  def lock(id, _) do
    :persistent_term.put(@key, id)
    :ok
  end

  @impl Terrarest.Storage
  def unlock(_) do
    :persistent_term.erase(@key)
    :ok
  end

  @impl Terrarest.Storage
  def check_lock(_) do
    case :persistent_term.get(@key) do
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
