defmodule StaffBot.DB.Users do
  alias StaffBot.Repo
  alias StaffBot.Domain.User
  require Logger

  def insert_user(username, installation_id) do
    case Repo.get_by(User, username: username) do
      nil ->
        Logger.info(
          "Adding new user with username: #{username} to installation #{installation_id}"
        )

        %User{}
        |> User.changeset(%{username: username, installation_id: installation_id})
        |> Repo.insert()

      # no update needed
      %User{installation_id: ^installation_id} = user ->
        Logger.info(
          "User already exists with username: #{username} on installation #{installation_id}"
        )

        {:ok, user}

      user ->
        Logger.info("Updating user: #{username} with new installation #{installation_id}")

        user
        |> User.changeset(%{installation_id: installation_id})
        |> Repo.update()
    end
  end

  def get_installation_id_by_username(username) do
    Repo.get_by(User, username: username)
    |> case do
      nil -> nil
      user -> user.installation_id
    end
  end
end
