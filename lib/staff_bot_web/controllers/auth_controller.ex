defmodule StaffBotWeb.AuthController do
  use StaffBotWeb, :controller
  plug Ueberauth
  require Logger

  alias StaffBot.DB.Users

  def request(conn, _params) do
    # Redirect to GitHub OAuth
    redirect(conn, external: Ueberauth.Strategy.Helpers.callback_url(conn))
  end

  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    Logger.error("GitHub OAuth failed: #{inspect(conn.assigns.ueberauth_failure)}")

    conn
    |> put_status(:unauthorized)
    |> json(%{error: "Authentication failed"})
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    %{
      info: %{nickname: username},
      credentials: %{token: access_token}
    } = auth

    Logger.info("GitHub OAuth successful for user: #{username}")
    Logger.info("Access token obtained with scopes: #{inspect(auth.credentials.scopes)}")

    # Store or update user with OAuth token
    case store_user_token(username, access_token) do
      {:ok, _user} ->
        conn
        |> put_status(:ok)
        |> json(%{
          message: "Authentication successful",
          user: username,
          scopes: auth.credentials.scopes
        })

      {:error, reason} ->
        Logger.error("Failed to store user token: #{inspect(reason)}")

        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Failed to store authentication"})
    end
  end

  defp store_user_token(username, access_token) do
    # Check if user exists, if not create them
    case Users.get_user_by_username(username) do
      nil ->
        # Create new user with OAuth token
        Users.insert_user_with_token(username, nil, access_token)

      _user ->
        # Update existing user with OAuth token
        Users.update_user_token(username, access_token)
    end
  end
end
