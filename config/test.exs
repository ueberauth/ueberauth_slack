use Mix.Config

config :ueberauth, :oauth2_client, Ueberauth.Client.OAuth2

config :ueberauth, Ueberauth.Strategy.Slack.OAuth,
  providers: [
    slack: {Ueberauth.Strategy.Slack, []}
  ]
