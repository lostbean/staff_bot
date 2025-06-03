defmodule StaffBotWeb.Router do
  use StaffBotWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", StaffBotWeb do
    pipe_through :api
    post "/webhook", WebhookController, :webhook
  end

  scope "/auth", StaffBotWeb do
    pipe_through :api

    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
  end
end
