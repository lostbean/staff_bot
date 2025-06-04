defmodule StaffBot.GitHub.Steps.UpdatePRStatusStep do
  @moduledoc """
  A reusable step for updating GitHub PR status checks.

  This step creates or updates a status check on a PR commit,
  allowing you to mark builds as pending, success, failure, or error.
  """

  use Reactor.Step

  alias StaffBot.GitHub.API
  require Logger

  @impl Reactor.Step
  def run(%{repo: repo, sha: sha, status: status, token: token} = args, _context, _step) do
    context = Map.get(args, :context, "ai-review")
    description = Map.get(args, :description, get_default_description(status))
    target_url = Map.get(args, :target_url)

    status_url = "https://api.github.com/repos/#{repo}/statuses/#{sha}"

    payload = %{
      state: status,
      context: context,
      description: description
    }

    payload = if target_url, do: Map.put(payload, :target_url, target_url), else: payload

    case API.post(status_url, payload, token) do
      {:ok, response} ->
        Logger.info("✅ PR status updated to '#{status}' for context '#{context}'")
        {:ok, response}

      {:error, reason} ->
        Logger.error("❌ Failed to update PR status: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp get_default_description("pending"), do: "AI review in progress"
  defp get_default_description("success"), do: "AI review completed successfully"
  defp get_default_description("failure"), do: "AI review found issues"
  defp get_default_description("error"), do: "AI review encountered an error"
  defp get_default_description(_), do: "AI review status update"
end
