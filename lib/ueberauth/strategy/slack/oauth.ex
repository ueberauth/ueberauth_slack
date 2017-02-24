defmodule Ueberauth.Strategy.Slack.OAuth do
  @moduledoc false
  use OAuth2.Strategy

  @defaults [
    strategy: __MODULE__,
    site: "https://slack.com/api",
    authorize_url: "https://slack.com/oauth/authorize",
    token_url: "https://slack.com/api/oauth.access"
  ]

  def client(opts \\ []) do
    slack_config = Application.get_env(:ueberauth, Ueberauth.Strategy.Slack.OAuth)
    client_opts =
      @defaults
      |> Keyword.merge(slack_config)
      |> Keyword.merge(opts)

    OAuth2.Client.new(client_opts)
  end

  def authorize_url!(params \\ [], opts \\ []) do
    opts
    |> client
    |> OAuth2.Client.authorize_url!(params)
  end

  def get_token!(params \\ [], options \\ %{}) do
    headers        = Dict.get(options, :headers, [])
    options        = Dict.get(options, :options, [])
    client_options = Dict.get(options, :client_options, [])
    OAuth2.Client.get_token!(client(client_options), params, headers, options)
  end

  # Strategy Callbacks

  def authorize_url(client, params) do
    OAuth2.Strategy.AuthCode.authorize_url(client, params)
  end

  def get_token(client, params, headers) do
    client
    |> put_header("Accept", "application/json")
    |> OAuth2.Strategy.AuthCode.get_token(params, headers)
  end
end
