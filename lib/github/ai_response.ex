defmodule StaffBot.GitHub.AiResponse do
  use Ecto.Schema
  use Instructor

  @llm_doc """
  AI code review response containing analysis of code changes against rules.

  ## Field Descriptions:
  - fixed_code: The corrected code that follows the rules, or "Nothing to Fix" if no issues found
  - reasoning: Explanation of why changes were needed, or "Nothing to reason about" if no issues
  - test_code: Suggested test code for the changes, or "No test case needed" if not applicable
  - rule: Summary of the rule that was violated, or "No rules violated" if compliant
  - rule_files: List of rule file names that were applied, or "No rules applicable" if none match
  """
  @primary_key false
  embedded_schema do
    field(:fixed_code, :string)
    field(:reasoning, :string)
    field(:test_code, :string)
    field(:rule, :string)
    field(:rule_files, :string)
  end

  def validate_changeset(changeset) do
    changeset
    |> Ecto.Changeset.validate_required([:fixed_code, :reasoning, :test_code, :rule, :rule_files])
    |> Ecto.Changeset.validate_length(:fixed_code, min: 1)
    |> Ecto.Changeset.validate_length(:reasoning, min: 1)
    |> Ecto.Changeset.validate_length(:test_code, min: 1)
    |> Ecto.Changeset.validate_length(:rule, min: 1)
    |> Ecto.Changeset.validate_length(:rule_files, min: 1)
  end
end
