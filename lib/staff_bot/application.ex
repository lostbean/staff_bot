defmodule StaffBot.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      StaffBotWeb.Telemetry,
      StaffBot.Repo,
      {Ecto.Migrator,
       repos: Application.fetch_env!(:staff_bot, :ecto_repos), skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:staff_bot, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: StaffBot.PubSub},
      {Finch, name: StaffBot.Finch},
      # Start a worker by calling: StaffBot.Worker.start_link(arg)
      # {StaffBot.Worker, arg},
      # Start to serve requests, typically the last entry
      StaffBotWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: StaffBot.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    StaffBotWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    # By default, sqlite migrations are run when using a release
    System.get_env("RELEASE_NAME") != nil
  end
end
