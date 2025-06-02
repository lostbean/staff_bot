defmodule StaffBot.GitHub.AiWorkflowTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog
  alias StaffBot.GitHub.{AiWorkflow, AiResponse}

  describe "get_rules/2" do
    @tag :skip
    test "returns empty map when rules folder does not exist" do
      # Skipped - requires external API setup
    end

    @tag :skip
    test "returns empty map when API returns error" do
      # Skipped - requires external API setup
    end
  end

  describe "format_ai_response/1" do
    test "formats valid AI response with all fields" do
      response = %AiResponse{
        fixed_code: "def hello, do: :world",
        reasoning: "Function was missing proper syntax",
        test_code: "test \"hello function\", do: assert hello() == :world",
        rule: "Proper function syntax required",
        rule_files: "rule01.md, rule02.md"
      }

      {:ok, formatted} = AiWorkflow.format_ai_response(response)

      assert formatted =~ "### ✅ Suggested Code:"
      assert formatted =~ "def hello, do: :world"
      assert formatted =~ "### 🧠 Reasoning:"
      assert formatted =~ "Function was missing proper syntax"
      assert formatted =~ "### 💣 Test Code:"
      assert formatted =~ "test \"hello function\""
      assert formatted =~ "### 📜 Rules applied:"
      assert formatted =~ "Proper function syntax required"
      assert formatted =~ "### 📁 Rule taken from:"
      assert formatted =~ "- rule01.md"
      assert formatted =~ "- rule02.md"
    end

    test "formats response with no rules applicable" do
      response = %AiResponse{
        fixed_code: "Nothing to Fix",
        reasoning: "Nothing to reason about",
        test_code: "No test case needed",
        rule: "No rules violated",
        rule_files: "No rules applicable"
      }

      {:ok, formatted} = AiWorkflow.format_ai_response(response)

      assert formatted =~ "Nothing to Fix"
      assert formatted =~ "Nothing to reason about"
      assert formatted =~ "No test case needed"
      assert formatted =~ "No rules violated"
      assert formatted =~ "- No rules applicable"
    end

    test "returns error for invalid response format" do
      invalid_response = %{invalid: "data"}

      capture_log(fn ->
        result = AiWorkflow.format_ai_response(invalid_response)
        assert {:error, "❌ Invalid AI response structure"} = result
      end)
    end
  end

  describe "generate_ai_response/2" do
    @tag :skip
    test "returns error when AI service is unavailable" do
      # Skipped - requires AI service setup
    end
  end
end
