defmodule StaffBot.GitHub.Steps.FetchRulesStep do
  @moduledoc """
  A reusable step for fetching AI code review rules from a GitHub repository.

  This step fetches rules from the 'ai-code-rules' directory in a repository
  and returns them as a map with filename as key and content as value.
  """

  use Reactor.Step

  alias StaffBot.GitHub.API
  require Logger

  @impl Reactor.Step
  def run(%{repo: repo, token: token}, _context, _step) do
    url = "https://api.github.com/repos/#{repo}/contents/ai-code-rules"

    with {:ok, file_list} when is_list(file_list) <- API.get(url, token) do
      rules =
        Enum.reduce(file_list, %{}, fn
          %{"type" => "file", "url" => file_url, "name" => name}, acc ->
            case fetch_and_decode_file(file_url, token) do
              {:ok, content} ->
                Map.put(acc, name, content)

              {:error, reason} ->
                Logger.error("❌ Failed to fetch #{name}: #{inspect(reason)}")
                acc
            end

          _, acc ->
            acc
        end)

      {:ok, rules}
    else
      {:error, reason} ->
        Logger.warning("⚠️ ai-code-rules folder does not exist: #{inspect(reason)}")
        {:ok, %{}}

      error ->
        Logger.error("❌ Unexpected error fetching rules: #{inspect(error)}")
        {:ok, %{}}
    end
  end

  defp fetch_and_decode_file(url, token) do
    with {:ok, %{"content" => encoded}} <- API.get(url, token),
         {:ok, decoded} <- Base.decode64(encoded, ignore: :whitespace) do
      {:ok, decoded}
    else
      {:error, reason} ->
        Logger.error("❌ Error: #{inspect(reason)}")
        {:error, reason}

      unexpected ->
        Logger.error("⚠️ Unexpected match: #{inspect(unexpected)}")
        {:error, :invalid_response}
    end
  end
end
