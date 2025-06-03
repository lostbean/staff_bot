defmodule StaffBot.Repo.Migrations.AddOauthTokenToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :oauth_token, :string
    end
  end
end
