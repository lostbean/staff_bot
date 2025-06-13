defmodule StaffBotWeb.WebhookController do
  use StaffBotWeb, :controller
  require Logger

  alias StaffBot.DB.Users
  alias StaffBot.GitHub.{EnhancedAiWorkflowReactor, JWT, API}

  defp github_secret, do: Application.get_env(:staff_bot, :github)[:secret]

  def webhook(conn, params) do
    signature = get_req_header(conn, "x-hub-signature-256") |> List.first()
    event_type = get_req_header(conn, "x-github-event") |> List.first()
    raw_body = conn.assigns[:raw_body]

    Logger.info("Webhook Triggered!")

    case github_secret() do
      nil ->
        Logger.warning("Not verified, GITHUB_SECRET not available")
        handle_event(event_type, params)
        json(conn, %{message: "Webhook received successfully"})

      secret ->
        cond do
          is_nil(signature) ->
            conn
            |> put_status(:bad_request)
            |> json(%{error: "Missing signature"})

          raw_body == nil ->
            conn
            |> put_status(:internal_server_error)
            |> json(%{error: "Internal error: raw body missing"})

          not valid_signature?(signature, secret, raw_body) ->
            Logger.warning("Invalid Signature")

            conn
            |> put_status(:forbidden)
            |> json(%{error: "Invalid signature"})

          true ->
            Logger.info("Webhook verified successfully")
            handle_event(event_type, params)
            json(conn, %{message: "Webhook received successfully"})
        end
    end
  end

  defp valid_signature?(header, secret, raw_body) do
    ["sha256", signature] = String.split(header, "=", parts: 2)

    digest =
      :crypto.mac(:hmac, :sha256, secret, raw_body)
      |> Base.encode16(case: :lower)

    Plug.Crypto.secure_compare(digest, signature)
  end

  defp handle_event("installation", %{
         "action" => action,
         "installation" => %{"id" => id, "account" => %{"login" => login}}
       })
       when action in ["added", "created"] do
    Logger.info("Handling User Installation.... ")
    Users.insert_user(login, to_string(id))
  end

  defp handle_event("installation_repositories", %{
         "action" => "added",
         "installation" => %{"id" => id, "account" => %{"login" => login}}
       }) do
    Logger.info("Handling User Installation.... ")
    Users.insert_user(login, to_string(id))
  end

  defp get_file_diff(payload) do
    case payload do
      %{"filename" => filename, "patch" => patch} -> %{filename => patch || ""}
        _ -> nil
    end
  end

  defp handle_event("pull_request", %{"action" => action} = data)
       when action in ["opened", "synchronize", "reopened"] do
    repo = data["repository"]
    pr = data["pull_request"]
    username = repo["owner"]["login"]
    repo_full_name = repo["full_name"]
    pr_number = data["number"]
    base_sha = pr["base"]["sha"]
    head_sha = pr["head"]["sha"]

    diff_url = "https://api.github.com/repos/#{repo_full_name}/compare/#{base_sha}...#{head_sha}"

    with {:ok, installation_id} <- fetch_installation_id(username),
         {:ok, access_token} <- fetch_access_token(installation_id),
         {:ok, %{"files" => files}} <- API.get(diff_url, access_token) do
      # Get the changes in the code

      code_diff =
        files
        |> Enum.map(&get_file_diff/1)
        |> Enum.filter(&(!is_nil(&1)))

      # Run enhanced AI workflow using Reactor
      case Reactor.run(EnhancedAiWorkflowReactor, %{
             repo: repo_full_name,
             token: access_token,
             code: code_diff,
             pr_number: pr_number,
             sha: head_sha
           }) do
        {:ok, _result} ->
          Logger.info("✅ AI workflow completed successfully!")

        {:error, reason} ->
          Logger.error("❌ AI workflow failed: #{inspect(reason)}")

          # Set PR status to error on failure
          status_url = "https://api.github.com/repos/#{repo_full_name}/statuses/#{head_sha}"

          API.post(
            status_url,
            %{
              state: "error",
              context: "ai-review",
              description: "AI review encountered an error"
            },
            access_token
          )
      end
    else
      {:error, reason} ->
        Logger.error("❌ GitHub integration failed: #{inspect(reason)}")
    end
  end

  defp handle_event(event_type, payload) do
    Logger.warning("Unhandled event_type #{event_type}")
    :ok
  end

  defp fetch_installation_id(username) do
    case Users.get_installation_id_by_username(username) do
      nil -> {:error, "User #{username} not found"}
      id -> {:ok, id}
    end
  end

  defp fetch_access_token(installation_id) do
    case JWT.generate_github_access_token(installation_id) do
      nil -> {:error, :token_generation_failed}
      token -> {:ok, token}
    end
  end
end
