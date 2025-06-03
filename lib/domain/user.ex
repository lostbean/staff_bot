defmodule StaffBot.Domain.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :username, :string
    field :installation_id, :string
    field :oauth_token, :string

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :installation_id, :oauth_token])
    |> validate_required([:username])
    |> unique_constraint(:installation_id)
  end
end
