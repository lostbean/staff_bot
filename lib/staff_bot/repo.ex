defmodule StaffBot.Repo do
  use Ecto.Repo,
    otp_app: :staff_bot,
    adapter: Ecto.Adapters.SQLite3
end
