defmodule StaffBot.GitHub.AiResponseTest do
  use ExUnit.Case, async: true
  alias StaffBot.GitHub.AiResponse

  describe "embedded schema" do
    test "has all required fields" do
      response = %AiResponse{
        fixed_code: "def hello, do: :world",
        reasoning: "Added proper function syntax",
        test_code: "test \"hello function\", do: assert hello() == :world",
        rule: "Function syntax rule",
        rule_files: "rule01.md"
      }

      assert response.fixed_code == "def hello, do: :world"
      assert response.reasoning == "Added proper function syntax"
      assert response.test_code == "test \"hello function\", do: assert hello() == :world"
      assert response.rule == "Function syntax rule"
      assert response.rule_files == "rule01.md"
    end
  end

  describe "validate_changeset/1" do
    test "validates all required fields are present" do
      changeset =
        %AiResponse{}
        |> Ecto.Changeset.change(%{
          fixed_code: "def test, do: :ok",
          reasoning: "Test reasoning",
          test_code: "test \"function\", do: assert true",
          rule: "Test rule",
          rule_files: "rule01.md"
        })
        |> AiResponse.validate_changeset()

      assert changeset.valid?
    end

    test "requires all fields to be present" do
      changeset =
        %AiResponse{}
        |> Ecto.Changeset.change(%{})
        |> AiResponse.validate_changeset()

      refute changeset.valid?
      assert {:fixed_code, {"can't be blank", [validation: :required]}} in changeset.errors
      assert {:reasoning, {"can't be blank", [validation: :required]}} in changeset.errors
      assert {:test_code, {"can't be blank", [validation: :required]}} in changeset.errors
      assert {:rule, {"can't be blank", [validation: :required]}} in changeset.errors
      assert {:rule_files, {"can't be blank", [validation: :required]}} in changeset.errors
    end

    test "validates minimum length for all fields" do
      changeset =
        %AiResponse{}
        |> Ecto.Changeset.change(%{
          fixed_code: "",
          reasoning: "",
          test_code: "",
          rule: "",
          rule_files: ""
        })
        |> AiResponse.validate_changeset()

      refute changeset.valid?

      # Check that length validation errors are present
      errors = changeset.errors
      assert Keyword.has_key?(errors, :fixed_code)
      assert Keyword.has_key?(errors, :reasoning)
      assert Keyword.has_key?(errors, :test_code)
      assert Keyword.has_key?(errors, :rule)
      assert Keyword.has_key?(errors, :rule_files)
    end

    test "accepts valid data with minimum length" do
      changeset =
        %AiResponse{}
        |> Ecto.Changeset.change(%{
          fixed_code: "x",
          reasoning: "y",
          test_code: "z",
          rule: "a",
          rule_files: "b"
        })
        |> AiResponse.validate_changeset()

      assert changeset.valid?
    end
  end
end
