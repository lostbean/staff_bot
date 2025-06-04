defmodule StaffBot.GitHub.Steps.FormatAiResponseStepTest do
  use ExUnit.Case, async: true

  alias StaffBot.GitHub.Steps.FormatAiResponseStep
  alias StaffBot.GitHub.AiResponse

  describe "run/2" do
    test "successfully formats a valid AI response" do
      response = %AiResponse{
        fixed_code: "```elixir\ndef hello, do: :world\n```",
        reasoning: "**Function Naming**: Use descriptive function names",
        test_code:
          "```elixir\ntest \"hello returns world\" do\n  assert hello() == :world\nend\n```",
        rule: "Use descriptive function names",
        rule_files: "naming.md, style.md"
      }

      assert {:ok, formatted} = FormatAiResponseStep.run(%{ai_response: response}, %{}, %{})

      assert String.contains?(formatted, "### ✅ Suggested Code:")
      assert String.contains?(formatted, "def hello, do: :world")
      assert String.contains?(formatted, "### 🧠 Reasoning:")
      assert String.contains?(formatted, "Function Naming")
      assert String.contains?(formatted, "### 💣 Test Code:")
      assert String.contains?(formatted, "test \"hello returns world\"")
      assert String.contains?(formatted, "### 📜 Rules applied:")
      assert String.contains?(formatted, "Use descriptive function names")
      assert String.contains?(formatted, "### 📁 Rule taken from:")
      assert String.contains?(formatted, "- naming.md")
      assert String.contains?(formatted, "- style.md")
    end

    test "handles response with no rules applicable" do
      response = %AiResponse{
        fixed_code: "Nothing to Fix",
        reasoning: "Nothing to reason about",
        test_code: "No test case needed",
        rule: "No rules violated",
        rule_files: "No rules applicable"
      }

      assert {:ok, formatted} = FormatAiResponseStep.run(%{ai_response: response}, %{}, %{})

      assert String.contains?(formatted, "Nothing to Fix")
      assert String.contains?(formatted, "Nothing to reason about")
      assert String.contains?(formatted, "No test case needed")
      assert String.contains?(formatted, "No rules violated")
      assert String.contains?(formatted, "- No rules applicable")
    end

    test "handles single rule file" do
      response = %AiResponse{
        fixed_code: "Fixed code here",
        reasoning: "Some reasoning",
        test_code: "Some test",
        rule: "Some rule",
        rule_files: "single_rule.md"
      }

      assert {:ok, formatted} = FormatAiResponseStep.run(%{ai_response: response}, %{}, %{})

      assert String.contains?(formatted, "- single_rule.md")
      refute String.contains?(formatted, "- ,")
    end

    test "handles multiple rule files with proper formatting" do
      response = %AiResponse{
        fixed_code: "Fixed code",
        reasoning: "Reasoning",
        test_code: "Test code",
        rule: "Rule",
        rule_files: "rule1.md, rule2.md, rule3.md"
      }

      assert {:ok, formatted} = FormatAiResponseStep.run(%{ai_response: response}, %{}, %{})

      assert String.contains?(formatted, "- rule1.md")
      assert String.contains?(formatted, "- rule2.md")
      assert String.contains?(formatted, "- rule3.md")
    end

    test "returns error for invalid response structure" do
      invalid_response = %{not_an_ai_response: true}

      assert {:error, "❌ Invalid AI response structure"} =
               FormatAiResponseStep.run(%{ai_response: invalid_response}, %{}, %{})
    end

    test "handles nil rule_files" do
      response = %AiResponse{
        fixed_code: "Fixed code",
        reasoning: "Reasoning",
        test_code: "Test code",
        rule: "Rule",
        rule_files: nil
      }

      assert {:ok, formatted} = FormatAiResponseStep.run(%{ai_response: response}, %{}, %{})

      assert String.contains?(formatted, "- ")
    end
  end
end
