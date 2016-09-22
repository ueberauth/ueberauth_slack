# Überauth Slack

> Slack OAuth2 strategy for Überauth.

## Installation

1. Setup your application at [Slack API](https://api.slack.com).

1. Add `:ueberauth_slack` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:ueberauth_slack, "~> 0.4"}]
    end
    ```

1. Add the strategy to your applications:

    ```elixir
    def application do
      [applications: [:ueberauth_slack]]
    end
    ```

1. Add Slack to your Überauth configuration:

    ```elixir
    config :ueberauth, Ueberauth,
      providers: [
        slack: {Ueberauth.Strategy.Slack, []}
      ]
    ```

    You can optionally restrict authentication by providing your team ID. [Find your Slack team ID here](https://api.slack.com/methods/auth.test/test). Note that this is NOT your team's Slack domain name!

    ```elixir
    config :ueberauth, Ueberauth,
      providers: [
        slack: {Ueberauth.Strategy.Slack, [team: "0ABCDEF"]}
      ]
    ```

1.  Update your provider configuration:

    ```elixir
    config :ueberauth, Ueberauth.Strategy.Slack.OAuth,
      client_id: System.get_env("SLACK_CLIENT_ID"),
      client_secret: System.get_env("SLACK_CLIENT_SECRET")
    ```

1.  Include the Überauth plug in your controller:

    ```elixir
    defmodule MyApp.AuthController do
      use MyApp.Web, :controller
      plug Ueberauth
      ...
    end
    ```

1.  Create the request and callback routes if you haven't already:

    ```elixir
    scope "/auth", MyApp do
      pipe_through :browser

      get "/:provider", AuthController, :request
      get "/:provider/callback", AuthController, :callback
    end
    ```

1. You controller needs to implement callbacks to deal with `Ueberauth.Auth` and `Ueberauth.Failure` responses.

For an example implementation see the [Überauth Example](https://github.com/ueberauth/ueberauth_example) application.

## Calling

Depending on the configured url you can initial the request through:

    /auth/slack

Or with options:

    /auth/slack?scope=users:read

By default the requested scope is "users:read". Scope can be configured either explicitly as a `scope` query value on the request path or in your configuration:

```elixir
config :ueberauth, Ueberauth,
  providers: [
    slack: {Ueberauth.Strategy.Slack, [default_scope: "users:read,users:write"]}
  ]
```

## License

Please see [LICENSE](https://github.com/ueberauth/ueberauth_slack/blob/master/LICENSE) for licensing details.

