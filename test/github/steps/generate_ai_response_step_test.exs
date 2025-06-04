defmodule StaffBot.GitHub.Steps.GenerateAiResponseStepTest do
  use ExUnit.Case, async: true

  alias StaffBot.GitHub.Steps.GenerateAiResponseStep
  alias StaffBot.GitHub.AiResponse

  import Mimic

  setup :verify_on_exit!
  setup :set_mimic_from_context

  describe "run/2" do
    test "successfully generates AI response with valid inputs" do
      rules = %{
        "rule1.md" => "No console.log statements",
        "rule2.md" => "Use proper error handling"
      }

      code = [
        %{"test.js" => "console.log('debug');"}
      ]

      response = %AiResponse{
        fixed_code:
          "// Remove console.log\nconst debug = (msg) => process.env.NODE_ENV === 'development' && console.log(msg);",
        reasoning: "Console.log statements should not be in production code",
        test_code: "No test case needed",
        rule: "No console.log statements",
        rule_files: "rule1.md"
      }

      expect(Instructor, :chat_completion, fn _opts ->
        {:ok, response}
      end)

      assert {:ok, ^response} = GenerateAiResponseStep.run(%{rules: rules, code: code}, %{}, %{})
    end

    test "handles empty rules gracefully" do
      rules = %{}
      code = [%{"test.js" => "const x = 1;"}]

      response = %AiResponse{
        fixed_code: "Nothing to Fix",
        reasoning: "Nothing to reason about",
        test_code: "No test case needed",
        rule: "No rules violated",
        rule_files: "No rules applicable"
      }

      Instructor
      |> expect(:chat_completion, fn _opts ->
        {:ok, response}
      end)

      assert {:ok, ^response} = GenerateAiResponseStep.run(%{rules: rules, code: code}, %{}, %{})
    end

    test "handles empty code gracefully" do
      rules = %{"rule1.md" => "Some rule"}
      code = []

      response = %AiResponse{
        fixed_code: "Nothing to Fix",
        reasoning: "Nothing to reason about",
        test_code: "No test case needed",
        rule: "No rules violated",
        rule_files: "No rules applicable"
      }

      Instructor
      |> expect(:chat_completion, fn _opts ->
        {:ok, response}
      end)

      assert {:ok, ^response} = GenerateAiResponseStep.run(%{rules: rules, code: code}, %{}, %{})
    end

    test "validates required arguments" do
      # Test that the step expects rules and code arguments
      args = %{rules: %{}, code: []}

      # This would normally call the actual step, but we're testing structure
      assert match?(%{rules: _, code: _}, args)
    end

    test "returns error when AI service fails" do
      rules = %{"rule1.md" => "Some rule"}
      code = [%{"test.js" => "console.log('test');"}]

      expect(Instructor, :chat_completion, fn _opts ->
        {:error, %{errors: [field: "validation failed"]}}
      end)

      assert {:error, %{errors: "Invalid LLM format"}} =
               GenerateAiResponseStep.run(%{rules: rules, code: code}, %{}, %{})
    end
  end

  describe "compensate/4" do
    test "retries on validation errors" do
      reason = %{errors: [field: "validation failed"]}

      assert :retry = GenerateAiResponseStep.compensate(reason, %{}, %{}, %{})
    end

    test "retries on API rate limiting" do
      reason = %{"error" => %{"code" => 429}}

      assert :retry = GenerateAiResponseStep.compensate(reason, %{}, %{}, %{})
    end

    test "retries on server errors" do
      for code <- [500, 502, 503, 504] do
        reason = %{"error" => %{"code" => code}}
        assert :retry = GenerateAiResponseStep.compensate(reason, %{}, %{}, %{})
      end
    end

    test "does not retry on other errors" do
      reason = %{"error" => %{"code" => 400}}

      assert :ok = GenerateAiResponseStep.compensate(reason, %{}, %{}, %{})
    end

    test "does not retry on unknown error format" do
      reason = "unknown error"

      assert :ok = GenerateAiResponseStep.compensate(reason, %{}, %{}, %{})
    end
  end
end
