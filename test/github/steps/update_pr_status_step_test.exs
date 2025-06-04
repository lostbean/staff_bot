defmodule StaffBot.GitHub.Steps.UpdatePRStatusStepTest do
  use ExUnit.Case, async: true

  alias StaffBot.GitHub.Steps.UpdatePRStatusStep
  alias StaffBot.GitHub.API

  import Mimic

  setup :verify_on_exit!
  setup :set_mimic_from_context

  describe "run/2" do
    test "successfully updates PR status with default context" do
      repo = "test/repo"
      sha = "abc123"
      status = "success"
      token = "test-token"

      expected_payload = %{
        state: "success",
        context: "ai-review",
        description: "AI review completed successfully"
      }

      expect(API, :post, fn url, payload, ^token ->
        assert url == "https://api.github.com/repos/test/repo/statuses/abc123"
        assert payload == expected_payload
        {:ok, %{"id" => 789}}
      end)

      args = %{repo: repo, sha: sha, status: status, token: token}
      assert {:ok, %{"id" => 789}} = UpdatePRStatusStep.run(args, %{}, %{})
    end

    test "updates PR status with custom context and description" do
      repo = "test/repo"
      sha = "def456"
      status = "pending"
      token = "test-token"
      context = "custom-check"
      description = "Custom check in progress"

      expected_payload = %{
        state: "pending",
        context: "custom-check",
        description: "Custom check in progress"
      }

      expect(API, :post, fn _url, payload, ^token ->
        assert payload == expected_payload
        {:ok, %{}}
      end)

      args = %{
        repo: repo,
        sha: sha,
        status: status,
        token: token,
        context: context,
        description: description
      }

      assert {:ok, %{}} = UpdatePRStatusStep.run(args, %{}, %{})
    end

    test "includes target_url when provided" do
      repo = "test/repo"
      sha = "ghi789"
      status = "failure"
      token = "test-token"
      target_url = "https://example.com/build/123"

      expected_payload = %{
        state: "failure",
        context: "ai-review",
        description: "AI review found issues",
        target_url: "https://example.com/build/123"
      }

      API
      |> expect(:post, fn _url, payload, ^token ->
        assert payload == expected_payload
        {:ok, %{}}
      end)

      args = %{
        repo: repo,
        sha: sha,
        status: status,
        token: token,
        target_url: target_url
      }

      assert {:ok, %{}} = UpdatePRStatusStep.run(args, %{}, %{})
    end

    test "handles API errors gracefully" do
      repo = "test/repo"
      sha = "error123"
      status = "error"
      token = "test-token"

      expect(API, :post, fn _url, _payload, ^token ->
        {:error, :unauthorized}
      end)

      args = %{repo: repo, sha: sha, status: status, token: token}
      assert {:error, :unauthorized} = UpdatePRStatusStep.run(args, %{}, %{})
    end

    test "uses correct default descriptions for different statuses" do
      test_cases = [
        {"pending", "AI review in progress"},
        {"success", "AI review completed successfully"},
        {"failure", "AI review found issues"},
        {"error", "AI review encountered an error"},
        {"unknown", "AI review status update"}
      ]

      expect(API, :post, 5, fn _url, payload, _token ->
        {_status, expected_description} =
          case payload.description do
            "AI review in progress" -> {"pending", "AI review in progress"}
            "AI review completed successfully" -> {"success", "AI review completed successfully"}
            "AI review found issues" -> {"failure", "AI review found issues"}
            "AI review encountered an error" -> {"error", "AI review encountered an error"}
            "AI review status update" -> {"unknown", "AI review status update"}
          end

        assert payload.description == expected_description
        {:ok, %{}}
      end)

      for {status, _expected_description} <- test_cases do
        args = %{repo: "test/repo", sha: "test123", status: status, token: "token"}
        UpdatePRStatusStep.run(args, %{}, %{})
      end
    end
  end
end
