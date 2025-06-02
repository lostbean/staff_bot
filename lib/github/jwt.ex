defmodule StaffBot.GitHub.JWT do
  require Logger

  defp github_private_key, do: Application.get_env(:staff_bot, :github)[:private_key]
  defp github_app_id, do: Application.get_env(:staff_bot, :github)[:app_id]

  # 5 minutes expiration
  def generate_github_access_token(installation_id) do
    claims = %{
      "iat" => now(),
      "exp" => now() + 300,
      "iss" => github_app_id()
    }

    # Read the private key from file
    private_key = github_private_key()

    # Convert the RSA private key into a JWK, then sign it and return the JWT string
    jwk = JOSE.JWK.from_pem(private_key)
    signed_jwt = JOSE.JWT.sign(jwk, %{"alg" => "RS256"}, claims)
    {_, jwt} = JOSE.JWS.compact(signed_jwt)

    # Get access_token for further API requests
    url = "https://api.github.com/app/installations/#{installation_id}/access_tokens"
    headers = [{"Authorization", "Bearer #{jwt}"}, {"Accept", "application/vnd.github+json"}]

    # Make the HTTP request using Finch
    Finch.build(:post, url, headers)
    |> Finch.request(StaffBot.Finch)
    |> case do
      {:ok, %{status: 201, body: body}} ->
        Jason.decode!(body)["token"]

      _ ->
        nil
    end
  end

  defp now(), do: DateTime.utc_now() |> DateTime.to_unix()
end
