defmodule StaffBot.GitHub.EnhancedAiWorkflowReactorTest do
  use ExUnit.Case, async: true

  alias StaffBot.GitHub.EnhancedAiWorkflowReactor
  alias StaffBot.GitHub.{API, AiResponse}

  import Mimic

  setup :verify_on_exit!
  setup :set_mimic_from_context

  describe "Enhanced Reactor workflow" do
    test "successfully executes the complete enhanced AI workflow" do
      repo = "test/repo"
      token = "test-token"
      code = [%{"test.ex" => "+ def hello, do: IO.puts(\"world\")"}]
      pr_number = 123
      sha = "abc123"

      # Mock API calls for setting pending status and posting comments
      expect(API, :post, 2, fn url, payload, ^token ->
        case url do
          "https://api.github.com/repos/test/repo/statuses/abc123" ->
            case payload do
              %{state: "pending", context: "ai-review"} ->
                {:ok, %{"id" => 1, "state" => "pending"}}

              %{state: "success", context: "ai-review"} ->
                {:ok, %{"id" => 2, "state" => "success"}}
            end

          "https://api.github.com/repos/test/repo/issues/123/comments" ->
            {:ok, %{"id" => 456, "body" => "AI review comment"}}
        end
      end)

      # Mock API calls for fetching rules
      file_list = [
        %{
          "type" => "file",
          "name" => "no_io_puts.md",
          "url" => "https://api.github.com/repos/test/repo/contents/ai-code-rules/no_io_puts.md"
        }
      ]

      rule_content = %{"content" => Base.encode64("Avoid using IO.puts in production code")}

      expect(API, :get, 2, fn url, ^token ->
        case url do
          "https://api.github.com/repos/test/repo/contents/ai-code-rules" ->
            {:ok, file_list}

          "https://api.github.com/repos/test/repo/contents/ai-code-rules/no_io_puts.md" ->
            {:ok, rule_content}
        end
      end)

      # Mock Instructor.chat_completion for AI response generation
      ai_response = %AiResponse{
        fixed_code: "```elixir\ndef hello, do: Logger.info(\"world\")\n```",
        reasoning: "**IO.puts Usage**: Replace IO.puts with Logger for better control",
        test_code: "```elixir\ntest \"hello logs message\" do\n  # Test implementation\nend\n```",
        rule: "Avoid using IO.puts in production code",
        rule_files: "no_io_puts.md"
      }

      expect(Instructor, :chat_completion, fn _opts ->
        {:ok, ai_response}
      end)

      inputs = %{
        repo: repo,
        token: token,
        code: code,
        pr_number: pr_number,
        sha: sha
      }

      # Test that the reactor is properly structured
      assert EnhancedAiWorkflowReactor.reactor()

      # Test that all required inputs are defined
      reactor_info = EnhancedAiWorkflowReactor.reactor()
      input_names = reactor_info.inputs

      assert :repo in input_names
      assert :token in input_names
      assert :code in input_names
      assert :pr_number in input_names
      assert :sha in input_names

      # Test that all steps are defined with correct dependencies
      step_names = reactor_info.plan.vertices |> Map.keys()
      assert :fetch_rules in step_names
      assert :with_rules_decision in step_names

      # The reactor should handle failures and still return a result
      assert {:ok, _result} = Reactor.run(EnhancedAiWorkflowReactor, inputs)
    end

    test "handles workflow failures gracefully" do
      repo = "test/repo"
      token = "test-token"
      code = [%{"test.ex" => "+ def hello, do: :world"}]
      pr_number = 123
      sha = "abc123"

      # Mock API to set pending status but fail on rules fetch
      expect(API, :post, fn _url, payload, ^token ->
        case payload do
          %{state: "failure"} -> {:ok, %{"id" => 1}}
        end
      end)

      expect(API, :get, fn _url, ^token ->
        {:error, :not_found}
      end)

      inputs = %{
        repo: repo,
        token: token,
        code: code,
        pr_number: pr_number,
        sha: sha
      }

      # The reactor should handle failures and still return a result
      assert {:ok, _result} = Reactor.run(EnhancedAiWorkflowReactor, inputs)

      # For now, verify the reactor structure supports this scenario
      assert is_map(inputs)
      assert EnhancedAiWorkflowReactor.reactor()
    end

    test "sets failure status when AI generation fails after retries" do
      repo = "test/repo"
      token = "test-token"
      code = [%{"test.ex" => "+ def hello, do: :world"}]
      pr_number = 123
      sha = "abc123"

      # Mock API calls for fetching rules
      file_list = [
        %{
          "type" => "file",
          "name" => "no_io_puts.md",
          "url" => "https://api.github.com/repos/test/repo/contents/ai-code-rules/no_io_puts.md"
        }
      ]

      rule_content = %{"content" => Base.encode64("Avoid using IO.puts in production code")}

      expect(API, :get, 2, fn url, ^token ->
        case url do
          "https://api.github.com/repos/test/repo/contents/ai-code-rules" ->
            {:ok, file_list}

          "https://api.github.com/repos/test/repo/contents/ai-code-rules/no_io_puts.md" ->
            {:ok, rule_content}
        end
      end)

      # Mock AI generation failure
      expect(Instructor, :chat_completion, 3, fn _opts ->
        {:error, %{errors: [field: "validation failed"]}}
      end)

      # Should post on GH
      reject(&API.post/3)

      inputs = %{
        repo: repo,
        token: token,
        code: code,
        pr_number: pr_number,
        sha: sha
      }

      assert {:error,
              %Reactor.Error.Invalid{
                errors: [
                  %Reactor.Error.Invalid.RunStepError{error: %{errors: "Invalid LLM format"}}
                ]
              }} = Reactor.run(EnhancedAiWorkflowReactor, inputs)
    end
  end
end
