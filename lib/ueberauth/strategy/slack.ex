defmodule Ueberauth.Strategy.Slack do
  @moduledoc """
  Implements an ÜeberauthSlack strategy for authentication with slack.com.

  When configuring the strategy in the Üeberauth providers, you can specify some defaults.

  * `uid_field` - The field to use as the UID field. This can be any populated field in the info struct. Default `:email`
  * `default_scope` - The scope to request by default from slack (permissions). Default "users:read"
  * `oauth2_module` - The OAuth2 module to use. Default Ueberauth.Strategy.Slack.OAuth

  ````elixir

  config :ueberauth, Ueberauth,
    providers: [
      slack: { Ueberauth.Strategy.Slack, [uid_field: :nickname, default_scope: "users:read,users:write"] }
    ]
  """
  use Ueberauth.Strategy, uid_field: :email,
                          default_scope: "users:read",
                          oauth2_module: Ueberauth.Strategy.Slack.OAuth

  alias Ueberauth.Auth.Info
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra

  # When handling the request just redirect to Slack
  @doc false
  def handle_request!(conn) do
    scopes = conn.params["scope"] || option(conn, :default_scope)
    opts = [ scope: scopes ]
    opts =
      if conn.params["state"], do: Keyword.put(opts, :state, conn.params["state"]), else: opts

    team = option(conn, :team)
    opts =
      if team, do: Keyword.put(opts, :team, team), else: opts

    callback_url = callback_url(conn)
    callback_url =
      if String.ends_with?(callback_url, "?"), do: String.slice(callback_url, 0..-2), else: callback_url

    opts = Keyword.put(opts, :redirect_uri, callback_url)
    module = option(conn, :oauth2_module)

    redirect!(conn, apply(module, :authorize_url!, [opts]))
  end

  # When handling the callback, if there was no errors we need to
  # make two calls. The first, to fetch the slack auth is so that we can get hold of
  # the user id so we can make a query to fetch the user info.
  # So that it is available later to build the auth struct, we put it in the private section of the conn.
  @doc false
  def handle_callback!(%Plug.Conn{ params: %{ "code" => code } } = conn) do
    module = option(conn, :oauth2_module)
    params = [code: code]
    options = %{
      options: [
        client_options: [redirect_uri: callback_url(conn)]
      ]
    }
    token = apply(module, :get_token!, [params, options])

    if token.access_token == nil do
      set_errors!(conn, [error(token.other_params["error"], token.other_params["error_description"])])
    else
      conn
      |> store_token(token)
      |> fetch_auth(token)
      |> fetch_user(token)
      |> fetch_team(token)
    end
  end

  # If we don't match code, then we have an issue
  @doc false
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  # We store the token for use later when fetching the slack auth and user and constructing the auth struct.
  @doc false
  defp store_token(conn, token) do
    put_private(conn, :slack_token, token)
  end

  # Remove the temporary storage in the conn for our data. Run after the auth struct has been built.
  @doc false
  def handle_cleanup!(conn) do
    conn
    |> put_private(:slack_auth, nil)
    |> put_private(:slack_user, nil)
    |> put_private(:slack_token, nil)
  end

  # The structure of the requests is such that it is difficult to provide cusomization for the uid field.
  # instead, we allow selecting any field from the info struct
  @doc false
  def uid(conn) do
    Map.get(info(conn), option(conn, :uid_field))
  end

  @doc false
  def credentials(conn) do
    token = conn.private.slack_token
    auth = conn.private.slack_auth
    user = conn.private.slack_user

    scopes = (token.other_params["scope"] || "")
    |> String.split(",")

    %Credentials{
      token: token.access_token,
      refresh_token: token.refresh_token,
      expires_at: token.expires_at,
      token_type: token.token_type,
      expires: !!token.expires_at,
      scopes: scopes,
      other: %{
        user: auth["user"],
        user_id: auth["user_id"],
        team: auth["team"],
        team_id: auth["team_id"],
        team_url: auth["url"],
        has_2fa: user["has_2fa"],
        is_admin: user["is_admin"],
        is_owner: user["is_owner"],
        is_primary_owner: user["is_primary_owner"],
        is_restricted: user["is_restricted"],
        is_ultra_restricted: user["is_ultra_restricted"],
      }
    }
  end

  @doc false
  def info(conn) do
    user = conn.private.slack_user
    auth = conn.private.slack_auth
    image_urls = user["profile"]
    |> Map.keys
    |> Enum.filter(&(&1 =~ ~r/^image_/))
    |> Enum.map(&({ &1, user["profile"][&1] }))
    |> Enum.into(%{})

    %Info{
      name: name_from_user(user),
      nickname: user["name"],
      email: user["profile"]["email"],
      image: user["profile"]["image_48"],
      urls: Map.merge(
        image_urls,
        %{
          team_url: auth["url"],
        }
      )
    }
  end

  @doc false
  def extra(conn) do
    %Extra {
      raw_info: %{
        auth: conn.private[:slack_auth],
        token: conn.private[:slack_token],
        user: conn.private[:slack_user],
        team: conn.private[:slack_team]
      }
    }
  end

  # Before we can fetch the user, we first need to fetch the auth to find out what the user id is.
  defp fetch_auth(conn, token) do
    case OAuth2.AccessToken.post(token, "/auth.test", [token: token.access_token], [{"Content-Type", "application/x-www-form-urlencoded"}]) do
      { :ok, %OAuth2.Response{status_code: 401, body: _body}} ->
        set_errors!(conn, [error("token", "unauthorized")])
      { :ok, %OAuth2.Response{status_code: status_code, body: auth} } when status_code in 200..399 ->
        if auth["ok"] do
          put_private(conn, :slack_auth, auth)
        else
          set_errors!(conn, [error(auth["error"], auth["error"])])
        end
      { :error, %OAuth2.Error{reason: reason} } ->
        set_errors!(conn, [error("OAuth2", reason)])
    end
  end

  # If the call to fetch the auth fails, we're going to have failures already in place.
  # If this happens don't try and fetch the user and just let it fail.
  defp fetch_user(%Plug.Conn{ assigns: %{ ueberauth_failure: _fails }} = conn, _), do: conn

  # Given the auth and token we can now fetch the user.
  defp fetch_user(conn, token) do
    auth = conn.private.slack_auth

    case OAuth2.AccessToken.post(token, "/users.info", [token: token.access_token, user: auth["user_id"]], [{"Content-Type", "application/x-www-form-urlencoded"}]) do
      { :ok, %OAuth2.Response{status_code: 401, body: _body}} ->
        set_errors!(conn, [error("token", "unauthorized")])
      { :ok, %OAuth2.Response{status_code: status_code, body: user} } when status_code in 200..399 ->
        if user["ok"] do
          put_private(conn, :slack_user, user["user"])
        else
          set_errors!(conn, [error(user["error"], user["error"])])
        end
      { :error, %OAuth2.Error{reason: reason} } ->
        set_errors!(conn, [error("OAuth2", reason)])
    end
  end

  defp fetch_team(%Plug.Conn{ assigns: %{ ueberauth_failure: _fails }} = conn, _), do: conn

  defp fetch_team(conn, token) do
    scopes = (token.other_params["scope"] || "")
    |> String.split(",")

    case "team:read" in scopes do
      false -> conn
      true  ->
        case OAuth2.AccessToken.post(token, "/team.info", [token: token.access_token], [{"Content-Type", "application/x-www-form-urlencoded"}]) do
          { :ok, %OAuth2.Response{status_code: 401, body: _body}} ->
            set_errors!(conn, [error("token", "unauthorized")])
          { :ok, %OAuth2.Response{status_code: status_code, body: team} } when status_code in 200..399 ->
            if team["ok"] do
              put_private(conn, :slack_team, team["team"])
            else
              set_errors!(conn, [error(team["error"], team["error"])])
            end
          { :error, %OAuth2.Error{reason: reason} } ->
            set_errors!(conn, [error("OAuth2", reason)])
        end
    end
  end

  # Fetch the name to use. We try to start with the most specific name avaialble and
  # fallback to the least.
  defp name_from_user(user) do
    [
      user["profile"]["real_name_normalized"],
      user["profile"]["real_name"],
      user["real_name"],
      user["name"],
    ]
    |> Enum.reject(&(&1 == "" || &1 == nil))
    |> List.first
  end

  defp option(conn, key) do
    Dict.get(options(conn), key, Dict.get(default_options, key))
  end
end
