defmodule Terrarest.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Terrarest.Router
    ]

    opts = [strategy: :one_for_one, name: Terrarest.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
