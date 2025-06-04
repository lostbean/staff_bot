defmodule StaffBot.GitHub.Steps.PostCommentStep do
  @moduledoc """
  A reusable step for posting comments to GitHub PRs or issues.

  This step takes a comment body, repository full name, issue/PR number,
  and access token to post a comment via the GitHub API.
  """

  use Reactor.Step

  alias StaffBot.GitHub.API
  require Logger

  @impl Reactor.Step
  def run(%{repo: repo, number: number, comment: comment, token: token}, _context, _step) do
    comment_url = "https://api.github.com/repos/#{repo}/issues/#{number}/comments"

    case API.post(comment_url, %{body: comment}, token) do
      {:ok, response} ->
        Logger.info("✏️ Comment posted successfully!")
        {:ok, response}

      {:error, reason} ->
        Logger.error("❌ Failed to post comment: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
