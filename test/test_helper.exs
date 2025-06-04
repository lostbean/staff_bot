Mimic.copy(StaffBot.GitHub.API)
Mimic.copy(Instructor)

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(StaffBot.Repo, :manual)
