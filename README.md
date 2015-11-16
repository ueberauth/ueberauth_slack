# ÜeberauthSlack

Proivdes an Üeberauth strategy to use Slack as the authentication mechanism.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

1. Add ueberauth\_slack to your list of dependencies in `mix.exs`:

````elixir
def deps do
  [{:ueberauth_slack, "~> 0.1.0"}]
end
````

2. Ensure oauth2 is started before your application:

```elixir
def application do
  [applications: [:oauth2]]
end
````

3. Head over to [slack and create an application](https://api.slack.com/applications). You can use
   http://localhost:4000/auth/slack/callback as the url for dev.

4. Add slack to your configuration (Phoenix)

````elixir
# To your ueberauth providers list
config :ueberauth, Ueberauth,
  providers: [
    slack: { Ueberauth.Strategy.Slack, [] }
  ]

# To provide access to the slack secrets

config :ueberauth, Ueberauth.Strategy.Slack.OAuth,
  client_id: System.get_env("SLACK_CLIENT_ID"),
  client_secret: System.get_env("SLACK_CLIENT_SECRET")
````

5. If you haven't already, create a pipeline for your Üeberauth

````elixir
pipeline :ueberauth do
  Ueberauth.plug "/auth"
end

scope "/auth" do
  pipe_through [:browser, :ueberauth]

  # it does not matter which contorller for the request phase
  # We just need to trigger the pipeline
  get "/slack", PagesController, :index
  get "/:provider/callback", AuthController, :callback
end
````

6. Implement your callback action in your controller to deal with an `Ueberauth.Auth` or `Ueberauth.Failure` callback

## Calling

To run through slack, depending on the url you setup with `Ueberauth.plug/1` you
can hit the url for the request phase.

    /auth/slack

Or with options

    /auth/slack?scope=users:read

By default the scope requested will be "users:read". This can be configured
either explicitly when you call the request path by providing a scope in the
query string, or by setting a default in your configuration.

````elixir
config :ueberauth, Ueberauth,
  providers: [
    slack: { Ueberauth.Strategy.Slack, [ default_scope: "users:read,users:write" ]
  ]
````

# License

The MIT License (MIT)

Copyright (c) 2015 Daniel Neighman

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
