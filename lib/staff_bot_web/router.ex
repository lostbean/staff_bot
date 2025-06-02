defmodule StaffBotWeb.Router do
  use StaffBotWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", StaffBotWeb do
    pipe_through :api
    post "/webhook", WebhookController, :webhook
  end
end
