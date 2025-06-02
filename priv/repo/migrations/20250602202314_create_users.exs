defmodule StaffBot.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :username, :string, null: false
      add :installation_id, :string, null: false

      timestamps()
    end

    create unique_index(:users, [:installation_id])
  end
end
