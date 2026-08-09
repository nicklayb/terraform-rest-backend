defmodule Terrarest.Storage.Provider.FileTest do
  use Terrarest.TestCase, async: false

  alias Terrarest.Storage.Provider.File, as: FileProvider

  setup [:init_provider, :init_persistent_term]

  @content ~s({"version": 1})

  @lock_key :test_terraform_lock

  describe "init/1" do
    @tag skip_init: true
    test "ensures directory created", %{
      provider_options: provider_options,
      storage_location: storage_location
    } do
      refute File.exists?(storage_location)
      assert :ok = FileProvider.init(provider_options)
      assert File.exists?(storage_location)
    end
  end

  describe "read/1" do
    test "reads existing file", %{
      provider_options: provider_options,
      storage_location: storage_location
    } do
      assert :ok =
               storage_location
               |> tfstate_file()
               |> File.write(@content)

      assert {:ok, @content} = FileProvider.read(provider_options)
    end
  end

  describe "store/2" do
    test "stores a file without backup if file doesn't exist", %{
      provider_options: provider_options,
      storage_location: storage_location
    } do
      refute tfstate_exists?(storage_location)

      assert :ok = FileProvider.store(@content, provider_options)
      assert tfstate_exists?(storage_location)
      refute tfstate_exists?(storage_location, :backup)
    end

    test "stores a file with backup if file exists", %{
      provider_options: provider_options,
      storage_location: storage_location
    } do
      assert :ok = FileProvider.store(@content, provider_options)
      assert tfstate_exists?(storage_location)
      assert {:ok, @content} = storage_location |> tfstate_file() |> File.read()

      new_content = ~s({"version": 2})
      assert @content != new_content
      assert :ok = FileProvider.store(new_content, provider_options)
      assert {:ok, ^new_content} = storage_location |> tfstate_file() |> File.read()
      assert {:ok, @content} = storage_location |> tfstate_file(:backup) |> File.read()
    end
  end

  describe "lock/2" do
    test "locks with a payload", %{
      provider_options: provider_options
    } do
      payload = %{"ID" => "id"}
      assert :undefined == :persistent_term.get(@lock_key, :undefined)
      assert :ok = FileProvider.lock(payload, provider_options)
      assert payload == :persistent_term.get(@lock_key)
    end

    test "overwrites with a new payload", %{
      provider_options: provider_options
    } do
      payload = %{"ID" => "id"}
      assert :ok = FileProvider.lock(payload, provider_options)
      assert payload == :persistent_term.get(@lock_key, :undefined)
      new_payload = %{"ID" => "new id"}

      assert new_payload != payload
      assert :ok = FileProvider.lock(new_payload, provider_options)
      assert new_payload == :persistent_term.get(@lock_key)
    end
  end

  describe "unlock/1" do
    test "unlocks by clearing whatevert value was there", %{
      provider_options: provider_options
    } do
      payload = %{"ID" => "id"}
      assert :ok = FileProvider.lock(payload, provider_options)
      assert payload == :persistent_term.get(@lock_key, :undefined)
      assert :ok = FileProvider.unlock(provider_options)
      assert :undefined == :persistent_term.get(@lock_key, :undefined)
      # Unlocking unlocked storage shouldn't break
      assert :undefined == :persistent_term.get(@lock_key, :undefined)
    end
  end

  describe "check_lock/1" do
    test "returns locked if locked", %{
      provider_options: provider_options
    } do
      assert :undefined == :persistent_term.get(@lock_key, :undefined)
      assert :unlocked = FileProvider.check_lock(provider_options)

      content = %{"ID" => "id"}
      assert :ok = FileProvider.lock(content, provider_options)
      assert {:locked, ^content} = FileProvider.check_lock(provider_options)
    end
  end

  defp init_persistent_term(_) do
    on_exit(fn -> :persistent_term.erase(@lock_key) end)
  end

  defp init_provider(context) do
    skip_init? = Map.get(context, :skip_init, false)
    storage_location = test_storage_location()
    provider_options = [location: storage_location, lock_key: @lock_key]

    File.rm_rf(storage_location)

    if not skip_init? do
      assert :ok == FileProvider.init(provider_options)

      assert File.exists?(storage_location)
    end

    on_exit(fn ->
      File.rm_rf(storage_location)
    end)

    [storage_location: storage_location, provider_options: provider_options]
  end

  defp test_storage_location do
    :terrarest
    |> :code.priv_dir()
    |> Path.join("test_storage")
  end

  defp tfstate_exists?(location, file \\ :main) do
    location
    |> tfstate_file(file)
    |> File.exists?()
  end

  @tfstate "terraform.tfstate"
  defp tfstate_file(location, file \\ :main) do
    filename =
      case file do
        :main -> @tfstate
        :backup -> @tfstate <> ".backup"
      end

    Path.join(location, filename)
  end
end
