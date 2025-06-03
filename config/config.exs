# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :staff_bot,
  ecto_repos: [StaffBot.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :staff_bot, StaffBotWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: StaffBotWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: StaffBot.PubSub,
  live_view: [signing_salt: "bw6XtSsT"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :instructor,
  adapter: Instructor.Adapters.Gemini,
  api_key: System.fetch_env!("GEMINI_API_KEY")

# GitHub configuration
config :staff_bot, :github, secret: System.get_env("GITHUB_SECRET")
config :staff_bot, :github, private_key: System.get_env("GITHUB_SECRET")
config :staff_bot, :github, app_id: System.get_env("GITHUB_APP_ID"")

# Ueberauth configuration
config :ueberauth, Ueberauth,
  providers: [
    github:
      {Ueberauth.Strategy.Github,
       [
         default_scope: "repo,issues:write,pull_requests:write",
         allow_private_emails: true
       ]}
  ]

config :ueberauth, Ueberauth.Strategy.Github.OAuth,
  client_id: System.get_env("GITHUB_CLIENT_ID"),
  client_secret: System.get_env("GITHUB_CLIENT_SECRET")

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
