defmodule StaffBot.GitHub.Steps.FormatAiResponseStep do
  @moduledoc """
  A reusable step for formatting AI responses into markdown comments.

  This step takes an AiResponse struct and formats it into a structured
  markdown comment suitable for GitHub PR reviews.
  """

  use Reactor.Step

  alias StaffBot.GitHub.AiResponse
  require Logger

  @impl Reactor.Step
  def run(%{ai_response: %AiResponse{} = response}, _context, _step) do
    formatted_comment = format_response(response)
    {:ok, formatted_comment}
  end

  def run(%{ai_response: invalid_response}, _context, _step) do
    Logger.error("⚠️ Unexpected format in AI response", response: invalid_response)
    {:error, "❌ Invalid AI response structure"}
  end

  defp format_response(%AiResponse{
         fixed_code: code,
         reasoning: reason,
         test_code: test_code,
         rule: rule,
         rule_files: files
       }) do
    rule_list = format_rule_files(files)

    """
    ### ✅ Suggested Code:

    #{code}

    ### 🧠 Reasoning:
    #{reason}

    ### 💣 Test Code:
    #{test_code}

    ### 📜 Rules applied:
    #{rule}

    ### 📁 Rule taken from:
    #{rule_list}
    """
  end

  defp format_rule_files(files) when files != nil and files != "No rules applicable" do
    files
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.map(&("- " <> &1))
    |> Enum.join("\n")
  end

  defp format_rule_files(files), do: "- #{files}"
end
