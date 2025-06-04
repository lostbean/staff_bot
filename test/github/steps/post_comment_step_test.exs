defmodule StaffBot.GitHub.Steps.PostCommentStepTest do
  use ExUnit.Case, async: true

  alias StaffBot.GitHub.Steps.PostCommentStep
  alias StaffBot.GitHub.API

  import Mimic

  setup :verify_on_exit!
  setup :set_mimic_from_context

  describe "run/2" do
    test "successfully posts comment to GitHub PR" do
      repo = "test/repo"
      number = 123
      comment = "This is a test comment"
      token = "test-token"

      expected_response = %{"id" => 456, "body" => comment}

      expect(API, :post, fn url, payload, ^token ->
        assert url == "https://api.github.com/repos/test/repo/issues/123/comments"
        assert payload == %{body: comment}
        {:ok, expected_response}
      end)

      args = %{repo: repo, number: number, comment: comment, token: token}
      assert {:ok, ^expected_response} = PostCommentStep.run(args, %{}, %{})
    end

    test "handles API errors gracefully" do
      repo = "test/repo"
      number = 123
      comment = "Test comment"
      token = "test-token"

      expect(API, :post, fn _url, _payload, ^token ->
        {:error, :rate_limited}
      end)

      args = %{repo: repo, number: number, comment: comment, token: token}
      assert {:error, :rate_limited} = PostCommentStep.run(args, %{}, %{})
    end

    test "constructs correct GitHub API URL for issues/PRs" do
      repo = "owner/repository"
      number = 42
      comment = "Comment text"
      token = "token123"

      expect(API, :post, fn url, _payload, _token ->
        assert url == "https://api.github.com/repos/owner/repository/issues/42/comments"
        {:ok, %{}}
      end)

      args = %{repo: repo, number: number, comment: comment, token: token}
      PostCommentStep.run(args, %{}, %{})
    end
  end
end
