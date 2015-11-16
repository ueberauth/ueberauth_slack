defmodule Ueberauth.Strategy.Slack.OAuth do
  use OAuth2.Strategy

  @defaults [
    strategy: __MODULE__,
    site: "https://slack.com/api",
    authorize_url: "https://slack.com/oauth/authorize",
    token_url: "https://slack.com/api/oauth.access"
  ]

  def client(opts \\ []) do
    opts = Keyword.merge(@defaults, Application.get_env(:ueberauth, Ueberauth.Strategy.Slack.OAuth))
    |> Keyword.merge(opts)

    OAuth2.Client.new(opts)
  end

  def authorize_url!(params \\ [], opts \\ []) do
    client(opts)
    |> OAuth2.Client.authorize_url!(params)
  end

  def get_token!(params \\ [], options \\ %{}) do
    headers = Dict.get(options, :headers, [])
    options = Dict.get(options, :options, [])
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
