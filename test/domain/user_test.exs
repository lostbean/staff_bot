defmodule StaffBot.Domain.UserTest do
  use StaffBot.DataCase, async: false
  alias StaffBot.Domain.User

  describe "changeset/2" do
    test "valid changeset with all required fields" do
      attrs = %{username: "testuser", installation_id: "12345"}
      changeset = User.changeset(%User{}, attrs)

      assert changeset.valid?
      assert changeset.changes.username == "testuser"
      assert changeset.changes.installation_id == "12345"
    end

    test "requires username" do
      attrs = %{installation_id: "12345"}
      changeset = User.changeset(%User{}, attrs)

      refute changeset.valid?
      assert {:username, {"can't be blank", [validation: :required]}} in changeset.errors
    end

    test "requires installation_id" do
      attrs = %{username: "testuser"}
      changeset = User.changeset(%User{}, attrs)

      refute changeset.valid?
      assert {:installation_id, {"can't be blank", [validation: :required]}} in changeset.errors
    end

    test "enforces unique constraint on installation_id" do
      # Insert first user
      attrs = %{username: "user1", installation_id: "12345"}
      changeset = User.changeset(%User{}, attrs)
      {:ok, _user} = Repo.insert(changeset)

      # Try to insert another user with same installation_id
      attrs2 = %{username: "user2", installation_id: "12345"}
      changeset2 = User.changeset(%User{}, attrs2)

      assert {:error, changeset} = Repo.insert(changeset2)

      assert {:installation_id,
              {"has already been taken",
               [constraint: :unique, constraint_name: "users_installation_id_index"]}} in changeset.errors
    end

    test "allows updating existing user" do
      # Insert user
      attrs = %{username: "testuser", installation_id: "12345"}
      changeset = User.changeset(%User{}, attrs)
      {:ok, user} = Repo.insert(changeset)

      # Update installation_id
      update_attrs = %{installation_id: "54321"}
      update_changeset = User.changeset(user, update_attrs)

      assert update_changeset.valid?
      assert update_changeset.changes.installation_id == "54321"
    end

    test "ignores extra fields not in schema" do
      attrs = %{username: "testuser", installation_id: "12345", extra_field: "ignored"}
      changeset = User.changeset(%User{}, attrs)

      assert changeset.valid?
      refute Map.has_key?(changeset.changes, :extra_field)
    end
  end
end
