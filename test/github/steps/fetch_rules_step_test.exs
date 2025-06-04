defmodule StaffBot.GitHub.Steps.FetchRulesStepTest do
  use ExUnit.Case, async: true

  alias StaffBot.GitHub.Steps.FetchRulesStep
  alias StaffBot.GitHub.API

  import Mimic

  setup :verify_on_exit!
  setup :set_mimic_from_context

  describe "run/2" do
    test "successfully fetches rules from repository" do
      repo = "test/repo"
      token = "test-token"

      file_list = [
        %{
          "type" => "file",
          "name" => "rule1.md",
          "url" => "https://api.github.com/repos/test/repo/contents/ai-code-rules/rule1.md"
        },
        %{
          "type" => "file",
          "name" => "rule2.md",
          "url" => "https://api.github.com/repos/test/repo/contents/ai-code-rules/rule2.md"
        }
      ]

      rule1_content = %{"content" => Base.encode64("Rule 1 content")}
      rule2_content = %{"content" => Base.encode64("Rule 2 content")}

      expect(API, :get, 3, fn url, ^token ->
        case url do
          "https://api.github.com/repos/test/repo/contents/ai-code-rules" ->
            {:ok, file_list}

          "https://api.github.com/repos/test/repo/contents/ai-code-rules/rule1.md" ->
            {:ok, rule1_content}

          "https://api.github.com/repos/test/repo/contents/ai-code-rules/rule2.md" ->
            {:ok, rule2_content}
        end
      end)

      assert {:ok, rules} = FetchRulesStep.run(%{repo: repo, token: token}, %{}, %{})

      assert %{
               "rule1.md" => "Rule 1 content",
               "rule2.md" => "Rule 2 content"
             } = rules
    end

    test "returns empty map when ai-code-rules folder does not exist" do
      repo = "test/repo"
      token = "test-token"

      expect(API, :get, fn _url, ^token ->
        {:error, :not_found}
      end)

      assert {:ok, %{}} = FetchRulesStep.run(%{repo: repo, token: token}, %{}, %{})
    end

    test "handles file decode errors gracefully" do
      repo = "test/repo"
      token = "test-token"

      file_list = [
        %{
          "type" => "file",
          "name" => "rule1.md",
          "url" => "https://api.github.com/repos/test/repo/contents/ai-code-rules/rule1.md"
        }
      ]

      expect(API, :get, fn url, ^token ->
        case url do
          "https://api.github.com/repos/test/repo/contents/ai-code-rules" ->
            {:ok, file_list}

          "https://api.github.com/repos/test/repo/contents/ai-code-rules/rule1.md" ->
            {:error, :decode_error}
        end
      end)

      assert {:ok, %{}} = FetchRulesStep.run(%{repo: repo, token: token}, %{}, %{})
    end

    test "filters out non-file entries" do
      repo = "test/repo"
      token = "test-token"

      file_list = [
        %{
          "type" => "dir",
          "name" => "subfolder"
        },
        %{
          "type" => "file",
          "name" => "rule1.md",
          "url" => "https://api.github.com/repos/test/repo/contents/ai-code-rules/rule1.md"
        }
      ]

      rule1_content = %{"content" => Base.encode64("Rule 1 content")}

      expect(API, :get, 2, fn url, ^token ->
        case url do
          "https://api.github.com/repos/test/repo/contents/ai-code-rules" ->
            {:ok, file_list}

          "https://api.github.com/repos/test/repo/contents/ai-code-rules/rule1.md" ->
            {:ok, rule1_content}
        end
      end)

      assert {:ok, rules} = FetchRulesStep.run(%{repo: repo, token: token}, %{}, %{})

      assert %{"rule1.md" => "Rule 1 content"} = rules
      refute Map.has_key?(rules, "subfolder")
    end
  end
end
