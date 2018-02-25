defmodule UeberauthSlackTest do
  use ExUnit.Case
  use Mix.Config
  
  doctest UeberauthSlack

  alias Ueberauth.Strategy.Slack.OAuth

  test "get_token! - an invalid code returns a nil access token" do
    params = [code: "abc123"]
    options =  %{ 
      :headers => [],
      :options => %{
        options: [client_options: [redirect_uri: "http://localhost:3000"]]
      }, 
      :client_options => [] 
    }

    %{access_token: token} = OAuth.get_token!(params, options)
  
    refute token
  end

  test "get_token! - a valid code returns a non-nil access token" do
    params = [code: "xyz456"]
    options =  %{ 
      :headers => [],
      :options => %{
        options: [client_options: [redirect_uri: "http://localhost:3000"]]
      }, 
      :client_options => [] 
    }

    %{access_token: token} = OAuth.get_token!(params, options)
  
    assert token
  end
end
