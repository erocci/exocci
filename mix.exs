defmodule OCCI.Mixfile do
  use Mix.Project

  def project do
    [app: :exocci,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [
      env: [
        model: OCCI.Model.Core
      ],
      applications: []
    ]
  end

  defp deps do
    [
      {:poison, "~> 3.1"},
      {:uuid, "~> 1.1"}
    ]
  end
end
