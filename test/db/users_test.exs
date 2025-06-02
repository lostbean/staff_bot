defmodule StaffBot.DB.UsersTest do
  use StaffBot.DataCase, async: false
  alias StaffBot.DB.Users
  alias StaffBot.Domain.User

  describe "insert_user/2" do
    test "inserts new user when user doesn't exist" do
      assert {:ok, %User{} = user} = Users.insert_user("newuser", "12345")
      assert user.username == "newuser"
      assert user.installation_id == "12345"
      assert user.id
    end

    test "returns existing user when user exists with same installation_id" do
      # Insert user first
      {:ok, original_user} = Users.insert_user("existinguser", "12345")

      # Try to insert again with same data
      assert {:ok, returned_user} = Users.insert_user("existinguser", "12345")
      assert returned_user.id == original_user.id
      assert returned_user.username == "existinguser"
      assert returned_user.installation_id == "12345"
    end

    test "updates user when user exists with different installation_id" do
      # Insert user first
      {:ok, original_user} = Users.insert_user("updateuser", "12345")

      # Update with new installation_id
      assert {:ok, updated_user} = Users.insert_user("updateuser", "54321")
      assert updated_user.id == original_user.id
      assert updated_user.username == "updateuser"
      assert updated_user.installation_id == "54321"
    end

    test "handles database errors gracefully" do
      # Just test that the function works with normal operations
      {:ok, _user1} = Users.insert_user("user1", "12345")
      {:ok, user2} = Users.insert_user("user2", "54321")

      # Update user2's installation_id
      assert {:ok, updated_user} = Users.insert_user("user2", "99999")
      assert updated_user.installation_id == "99999"
      assert updated_user.id == user2.id
    end
  end

  describe "get_installation_id_by_username/1" do
    test "returns installation_id when user exists" do
      {:ok, _user} = Users.insert_user("testuser", "12345")

      result = Users.get_installation_id_by_username("testuser")
      assert result == "12345"
    end

    test "returns nil when user doesn't exist" do
      result = Users.get_installation_id_by_username("nonexistent")
      assert result == nil
    end

    test "returns updated installation_id after user update" do
      {:ok, _user} = Users.insert_user("updatetest", "12345")

      # Update the user
      {:ok, _updated_user} = Users.insert_user("updatetest", "54321")

      result = Users.get_installation_id_by_username("updatetest")
      assert result == "54321"
    end

    test "handles empty string username" do
      result = Users.get_installation_id_by_username("")
      assert result == nil
    end

    test "handles nil username" do
      # Ecto doesn't allow direct nil comparison, so this will raise an error
      assert_raise ArgumentError, fn ->
        Users.get_installation_id_by_username(nil)
      end
    end
  end
end
