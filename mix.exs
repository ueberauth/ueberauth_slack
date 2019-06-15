defmodule UeberauthSlack.Mixfile do
  use Mix.Project

  @version "0.6.0"

  def project do
    [
      app: :ueberauth_slack,
      version: @version,
      name: "Ueberauth Slack",
      package: package(),
      elixir: "~> 1.4",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      source_url: "https://github.com/hassox/ueberauth_slack",
      homepage_url: "https://github.com/hassox/ueberauth_slack",
      description: description(),
      deps: deps(),
      docs: docs()
    ]
  end

  def application do
    [applications: [:logger, :ueberauth, :oauth2]]
  end

  defp deps do
    [
      {:oauth2, "~> 1.0"},
      {:ueberauth, "~> 0.6"},
      {:jason, "~> 1.0"},

      # dev/test dependencies
      {:credo, "~> 0.5", only: [:dev, :test]},
      {:earmark, ">= 0.0.0", only: :dev},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp docs do
    [extras: ["README.md", "CONTRIBUTING.md"]]
  end

  defp description do
    "An Ueberauth strategy for using Slack to authenticate your users"
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md"],
      maintainers: ["Daniel Neighman"],
      licenses: ["MIT"],
      links: %{GitHub: "https://github.com/hassox/ueberauth_slack"}
    ]
  end
end
