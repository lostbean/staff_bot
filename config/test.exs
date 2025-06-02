import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :staff_bot, StaffBot.Repo,
  database: Path.expand("../staff_bot_test.db", __DIR__),
  pool_size: 5,
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :staff_bot, StaffBotWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 8009],
  secret_key_base: "Di3h3rL9l/ER4hmV8CxOcGJGYJS/Ao4fchRrwenBG9q2qfq+PRMV533W76nX0gti",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
