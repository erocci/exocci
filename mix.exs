defmodule OCCI.Mixfile do
  use Mix.Project

  def project do
    [
      app: :occi,
      version: "0.2.3",
      elixir: ">= 1.3.4",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(Mix.env()),
      deps: deps(),
      name: "exocci",
      description: description(),
      package: package(),
      source_url: "https://github.com/erocci/exocci",
      homepage_url: "https://github.com/erocci/exocci",
      docs: docs()
    ]
  end

  def application do
    [
      env: [
        model: OCCI.Model.Core
      ]
    ]
  end

  defp description do
    """
    exocci provides libs and DSL for designing and manipulating OCCI
    (meta-)models.
    """
  end

  defp package do
    [
      name: :occi,
      maintainers: ["Jean Parpaillon"],
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => "https://github.com/erocci/exocci"
      }
    ]
  end

  defp deps do
    [
      {:occi_types, ">= 0.0.0"},
      {:credo, "~> 0.9", only: [:dev, :test], runtime: false},
      {:poison, "~> 3.1"},
      {:uuid, "~> 1.1"},
      {:earmark, "~> 1.2", only: :dev},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: "OCCI",
      logo: "_doc/erocci-logo-only.png",
      extras: ["_doc/manual.md"],
      source_url: "https://github.com/erocci/exocci",
      groups_for_modules: [
        Core: [
          OCCI,
          OCCI.Model,
          OCCI.Category,
          OCCI.Category.Helpers,
          OCCI.Kind,
          OCCI.Mixin,
          OCCI.Action,
          OCCI.Attribute,
          OCCI.OrdSet
        ],
        # "Attribute Types": ~r/^OCCI.Types.?/,
        Datastore: [
          OCCI.Store,
          OCCI.Backend,
          OCCI.Backend.Agent,
          OCCI.Filter,
          OCCI.Node
        ],
        Renderings: [
          OCCI.Rendering.JSON
        ],
        "Core Categories": ~r/^OCCI.Model.Core.?/,
        "Standard Categories": ~r/^OCCI.Model.Infrastructure.?/
      ]
    ]
  end

  defp aliases(env) when env in [:dev, :test] do
    [
      compile: ["format", "compile", "credo"]
    ]
  end

  defp aliases(_), do: []
end
