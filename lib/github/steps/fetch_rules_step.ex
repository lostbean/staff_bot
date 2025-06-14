defmodule StaffBot.GitHub.Steps.FetchRulesStep do
  @moduledoc """
  A flexible step for fetching AI code review rules from a GitHub repository.

  Supports configurable patterns for fetching multiple markdown files from various
  locations in the repository. Patterns can include:
  - Specific files: "CLAUDE.md", "claude.md"
  - Directory globs: "ai-code-rules/*.md", "docs/**/*.md"

  Configuration can be overridden via environment variables.
  """

  use Reactor.Step

  alias StaffBot.GitHub.API
  require Logger

  @impl Reactor.Step
  def run(%{repo: repo, token: token}, _context, _step) do
    patterns = get_patterns()

    Logger.info("🔍 Fetching rules from patterns: #{inspect(patterns)}")

    rules =
      patterns
      |> Enum.reduce(%{}, fn pattern, acc ->
        case fetch_files_for_pattern(repo, token, pattern) do
          {:ok, pattern_rules} ->
            Map.merge(acc, pattern_rules)

          {:error, reason} ->
            Logger.info("⚠️ Pattern '#{pattern}' failed: #{inspect(reason)}")
            acc
        end
      end)

    {:ok, rules}
  rescue
    e ->
      Exception.format(:error, e, __STACKTRACE__) |> Logger.warning()
      {:error, e}
  end

  defp get_patterns do
    case System.get_env("GITHUB_RULES_PATTERNS") do
      nil ->
        Application.get_env(:staff_bot, :github_rules, [])
        |> Keyword.get(:patterns, ["CLAUDE.md"])

      env_patterns ->
        env_patterns
        |> String.split(",")
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&(&1 == ""))
    end
  end

  defp fetch_files_for_pattern(repo, token, pattern) do
    cond do
      String.contains?(pattern, "*") ->
        fetch_glob_pattern(repo, token, pattern)

      String.ends_with?(pattern, ".md") ->
        fetch_single_file(repo, token, pattern)

      true ->
        fetch_directory_files(repo, token, pattern)
    end
  end

  defp fetch_single_file(repo, token, file_path) do
    url = "https://api.github.com/repos/#{repo}/contents/#{file_path}"

    case fetch_and_decode_file(url, token) do
      {:ok, content} ->
        filename = Path.basename(file_path)
        {:ok, %{filename => content}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp fetch_directory_files(repo, token, dir_path) do
    url = "https://api.github.com/repos/#{repo}/contents/#{dir_path}"

    with {:ok, file_list} when is_list(file_list) <- API.get(url, token) do
      rules =
        file_list
        |> Enum.filter(&(&1["type"] == "file" and String.ends_with?(&1["name"], ".md")))
        |> Enum.reduce(%{}, fn file_info, acc ->
          case fetch_and_decode_file(file_info["url"], token) do
            {:ok, content} ->
              Map.put(acc, file_info["name"], content)

            {:error, reason} ->
              Logger.error("❌ Failed to fetch #{file_info["name"]}: #{inspect(reason)}")
              acc
          end
        end)

      {:ok, rules}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp fetch_glob_pattern(repo, token, pattern) do
    {base_path, glob} = parse_glob_pattern(pattern)

    case fetch_directory_tree(repo, token, base_path) do
      {:ok, files} ->
        matching_files = filter_files_by_glob(files, base_path, glob)
        fetch_matching_files(matching_files, token)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp parse_glob_pattern(pattern) do
    parts = String.split(pattern, "/")
    {base_parts, glob_parts} = Enum.split_while(parts, &(not String.contains?(&1, "*")))

    base_path = Enum.join(base_parts, "/")
    glob = Enum.join(glob_parts, "/")

    {base_path, glob}
  end

  defp fetch_directory_tree(repo, token, base_path) do
    url =
      if base_path == "" do
        "https://api.github.com/repos/#{repo}/contents"
      else
        "https://api.github.com/repos/#{repo}/contents/#{base_path}"
      end

    case API.get(url, token) do
      {:ok, contents} when is_list(contents) ->
        files = collect_all_files(repo, token, contents, base_path)
        {:ok, files}

      {:ok, single_file} when is_map(single_file) ->
        {:ok, [single_file]}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp collect_all_files(repo, token, contents, base_path) do
    Enum.flat_map(contents, fn item ->
      case item["type"] do
        "file" ->
          [item]

        "dir" ->
          subdir_path = if base_path == "", do: item["name"], else: "#{base_path}/#{item["name"]}"

          case fetch_directory_tree(repo, token, subdir_path) do
            {:ok, subfiles} -> subfiles
            {:error, _} -> []
          end

        _ ->
          []
      end
    end)
  end

  defp filter_files_by_glob(files, base_path, glob) do
    Enum.filter(files, fn file ->
      full_path = file["path"] || file["name"]

      file_path =
        if base_path == "" do
          full_path
        else
          String.replace_prefix(full_path, "#{base_path}/", "")
        end

      matches_glob?(file_path, glob) and String.ends_with?(file["name"], ".md")
    end)
  end

  defp matches_glob?(path, glob) do
    # Simple but effective glob matching
    # Convert glob to regex, handling ** and * properly
    case glob do
      "**/*.md" ->
        # Special case for this common pattern: matches files ending in .md at any depth
        String.ends_with?(path, ".md")

      _ ->
        # General case: convert glob to regex
        regex_pattern =
          glob
          |> String.replace(".", "\\.")
          # ** matches any character including /
          |> String.replace("**", ".*")
          # * matches any character except /
          |> String.replace("*", "[^/]*")

        Regex.match?(~r/^#{regex_pattern}$/, path)
    end
  end

  defp fetch_matching_files(files, token) do
    rules =
      files
      |> Enum.reduce(%{}, fn file, acc ->
        case fetch_and_decode_file(file["url"], token) do
          {:ok, content} ->
            Map.put(acc, file["name"], content)

          {:error, reason} ->
            Logger.error("❌ Failed to fetch #{file["name"]}: #{inspect(reason)}")
            acc
        end
      end)

    {:ok, rules}
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
