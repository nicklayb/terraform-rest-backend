defmodule ExTemplate.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_template,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {ExTemplate.Application, []}
    ]
  end

  defp deps do
    [
      {:box, git: "https://github.com/nicklayb/box_ex.git", tag: "0.17.6"}
    ]
  end
end
