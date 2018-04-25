defmodule Ueberauth.Client.OAuth2 do
  def get_token!(_, [code: code] \\ [], _ \\ [], _ \\ []) do
    case code do
      "abc123" -> %{
        token: %OAuth2.AccessToken{
          access_token: nil,
          expires_at: nil,
          other_params: %{"error" => "invalid_code", "ok" => false},
          refresh_token: nil,
          token_type: "Bearer"
        } 
      }    
      "xyz456" -> %{
        token: %OAuth2.AccessToken{
          access_token: "asdf-1234-klsc",
          expires_at: nil,
          other_params: %{"ok" => true},
          refresh_token: nil,
          token_type: "Bearer"
        }
      }
    end
  end
end
