defmodule OCCI.Mixfile do
  use Mix.Project

  def project do
    [
      app: :occi,
      version: "0.1.0",
      elixir: "~> 1.3",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),

      name: "exocci",
      description: description(),
      package: package(),
      source_url: "https://github.com/erocci/exocci",
      homepage_url: "https://github.com/erocci/exocci",
      docs: [
        main: "OCCI",
        logo: "_doc/erocci-logo-only.png",
        extras: [ "_doc/manual.md" ]
      ]
    ]
  end

  def application do
    [
      env: [
        model: OCCI.Model.Core
      ],
      applications: []
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
      {:poison, "~> 3.1"},
      {:uuid, "~> 1.1"},
      {:earmark, "~> 1.2", only: :dev},
      {:ex_doc, "~> 0.15", only: :dev, runtime: false}
    ]
  end
end
