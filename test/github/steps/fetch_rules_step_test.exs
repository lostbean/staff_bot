defmodule StaffBot.GitHub.Steps.FetchRulesStepTest do
  use ExUnit.Case, async: true

  alias StaffBot.GitHub.Steps.FetchRulesStep
  alias StaffBot.GitHub.API

  import Mimic

  setup :verify_on_exit!
  setup :set_mimic_from_context

  describe "run/3 with default configuration" do
    test "successfully fetches CLAUDE.md from root when no config provided" do
      repo = "test/repo"
      token = "test-token"

      file_content = %{"content" => Base.encode64("# Claude Instructions\nTest content")}

      expect(API, :get, fn url, ^token ->
        case url do
          "https://api.github.com/repos/test/repo/contents/CLAUDE.md" ->
            {:ok, file_content}
        end
      end)

      assert {:ok, rules} = FetchRulesStep.run(%{repo: repo, token: token}, %{}, %{})
      assert %{"CLAUDE.md" => "# Claude Instructions\nTest content"} = rules
    end

    test "handles missing CLAUDE.md gracefully" do
      repo = "test/repo"
      token = "test-token"

      expect(API, :get, fn _url, ^token ->
        {:error, :not_found}
      end)

      assert {:ok, %{}} = FetchRulesStep.run(%{repo: repo, token: token}, %{}, %{})
    end
  end

  describe "run/3 with configured patterns" do
    setup do
      original_config = Application.get_env(:staff_bot, :github_rules, [])

      Application.put_env(:staff_bot, :github_rules,
        patterns: ["CLAUDE.md", "claude.md", "ai-code-rules/*.md"]
      )

      on_exit(fn ->
        Application.put_env(:staff_bot, :github_rules, original_config)
      end)
    end

    test "fetches multiple files from different patterns" do
      repo = "test/repo"
      token = "test-token"

      claude_content = %{"content" => Base.encode64("# Claude Instructions")}
      _claude_lower_content = %{"content" => Base.encode64("# claude instructions")}

      ai_rules_list = [
        %{
          "type" => "file",
          "name" => "rule1.md",
          "url" => "https://api.github.com/repos/test/repo/contents/ai-code-rules/rule1.md"
        }
      ]

      rule1_content = %{"content" => Base.encode64("Rule 1 content")}

      expect(API, :get, 4, fn url, ^token ->
        case url do
          "https://api.github.com/repos/test/repo/contents/CLAUDE.md" ->
            {:ok, claude_content}

          "https://api.github.com/repos/test/repo/contents/claude.md" ->
            {:error, :not_found}

          "https://api.github.com/repos/test/repo/contents/ai-code-rules" ->
            {:ok, ai_rules_list}

          "https://api.github.com/repos/test/repo/contents/ai-code-rules/rule1.md" ->
            {:ok, rule1_content}
        end
      end)

      assert {:ok, rules} = FetchRulesStep.run(%{repo: repo, token: token}, %{}, %{})

      assert %{
               "CLAUDE.md" => "# Claude Instructions",
               "rule1.md" => "Rule 1 content"
             } = rules
    end
  end

  describe "run/3 with environment variable override" do
    test "uses environment variable patterns when set" do
      repo = "test/repo"
      token = "test-token"

      # Set environment variable
      System.put_env("GITHUB_RULES_PATTERNS", "custom.md,docs/*.md")

      on_exit(fn ->
        System.delete_env("GITHUB_RULES_PATTERNS")
      end)

      custom_content = %{"content" => Base.encode64("Custom content")}

      docs_list = [
        %{
          "type" => "file",
          "name" => "doc1.md",
          "url" => "https://api.github.com/repos/test/repo/contents/docs/doc1.md"
        }
      ]

      doc1_content = %{"content" => Base.encode64("Doc 1 content")}

      expect(API, :get, 3, fn url, ^token ->
        case url do
          "https://api.github.com/repos/test/repo/contents/custom.md" ->
            {:ok, custom_content}

          "https://api.github.com/repos/test/repo/contents/docs" ->
            {:ok, docs_list}

          "https://api.github.com/repos/test/repo/contents/docs/doc1.md" ->
            {:ok, doc1_content}
        end
      end)

      assert {:ok, rules} = FetchRulesStep.run(%{repo: repo, token: token}, %{}, %{})

      assert %{
               "custom.md" => "Custom content",
               "doc1.md" => "Doc 1 content"
             } = rules
    end
  end

  describe "glob pattern matching" do
    test "handles nested directory globs" do
      repo = "test/repo"
      token = "test-token"

      System.put_env("GITHUB_RULES_PATTERNS", "docs/**/*.md")

      on_exit(fn ->
        System.delete_env("GITHUB_RULES_PATTERNS")
      end)

      # Mock root docs directory
      docs_root = [
        %{
          "type" => "dir",
          "name" => "guides",
          "path" => "docs/guides"
        },
        %{
          "type" => "file",
          "name" => "readme.md",
          "path" => "docs/readme.md",
          "url" => "https://api.github.com/repos/test/repo/contents/docs/readme.md"
        }
      ]

      # Mock subdirectory
      guides_dir = [
        %{
          "type" => "file",
          "name" => "guide1.md",
          "path" => "docs/guides/guide1.md",
          "url" => "https://api.github.com/repos/test/repo/contents/docs/guides/guide1.md"
        }
      ]

      readme_content = %{"content" => Base.encode64("Readme content")}
      guide1_content = %{"content" => Base.encode64("Guide 1 content")}

      expect(API, :get, 4, fn url, ^token ->
        case url do
          "https://api.github.com/repos/test/repo/contents/docs" ->
            {:ok, docs_root}

          "https://api.github.com/repos/test/repo/contents/docs/guides" ->
            {:ok, guides_dir}

          "https://api.github.com/repos/test/repo/contents/docs/readme.md" ->
            {:ok, readme_content}

          "https://api.github.com/repos/test/repo/contents/docs/guides/guide1.md" ->
            {:ok, guide1_content}
        end
      end)

      assert {:ok, rules} = FetchRulesStep.run(%{repo: repo, token: token}, %{}, %{})

      assert %{
               "readme.md" => "Readme content",
               "guide1.md" => "Guide 1 content"
             } = rules
    end
  end

  describe "error handling" do
    test "continues processing other patterns when one fails" do
      repo = "test/repo"
      token = "test-token"

      System.put_env("GITHUB_RULES_PATTERNS", "missing.md,CLAUDE.md")

      on_exit(fn ->
        System.delete_env("GITHUB_RULES_PATTERNS")
      end)

      claude_content = %{"content" => Base.encode64("Claude content")}

      expect(API, :get, 2, fn url, ^token ->
        case url do
          "https://api.github.com/repos/test/repo/contents/missing.md" ->
            {:error, :not_found}

          "https://api.github.com/repos/test/repo/contents/CLAUDE.md" ->
            {:ok, claude_content}
        end
      end)

      assert {:ok, rules} = FetchRulesStep.run(%{repo: repo, token: token}, %{}, %{})
      assert %{"CLAUDE.md" => "Claude content"} = rules
    end

    test "handles directory processing with no markdown files" do
      repo = "test/repo"
      token = "test-token"

      System.put_env("GITHUB_RULES_PATTERNS", "empty-dir")

      on_exit(fn ->
        System.delete_env("GITHUB_RULES_PATTERNS")
      end)

      empty_dir_list = [
        %{
          "type" => "file",
          "name" => "config.json"
        }
      ]

      expect(API, :get, fn url, ^token ->
        case url do
          "https://api.github.com/repos/test/repo/contents/empty-dir" ->
            {:ok, empty_dir_list}
        end
      end)

      assert {:ok, rules} = FetchRulesStep.run(%{repo: repo, token: token}, %{}, %{})
      assert %{} = rules
    end
  end
end
