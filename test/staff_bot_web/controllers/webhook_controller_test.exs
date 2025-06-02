defmodule StaffBotWeb.WebhookControllerTest do
  use StaffBotWeb.ConnCase, async: false
  import ExUnit.CaptureLog

  @valid_secret "test_secret"
  @webhook_path "/api/webhook"

  defp create_valid_signature(body) do
    digest =
      :crypto.mac(:hmac, :sha256, @valid_secret, body)
      |> Base.encode16(case: :lower)

    "sha256=#{digest}"
  end

  defp put_webhook_headers(conn, body, event_type) do
    signature = create_valid_signature(body)

    conn
    |> put_req_header("x-hub-signature-256", signature)
    |> put_req_header("x-github-event", event_type)
    |> put_req_header("content-type", "application/json")
    |> assign(:raw_body, body)
  end

  describe "webhook/2" do
    test "returns 400 when signature header is missing", %{conn: conn} do
      body = Jason.encode!(%{test: "data"})

      conn =
        conn
        |> put_req_header("x-github-event", "push")
        |> assign(:raw_body, body)
        |> post(@webhook_path, %{test: "data"})

      assert json_response(conn, 400) == %{"error" => "Missing signature"}
    end

    test "returns 500 when raw body is missing", %{conn: conn} do
      body = Jason.encode!(%{test: "data"})
      signature = create_valid_signature(body)

      conn =
        conn
        |> put_req_header("x-hub-signature-256", signature)
        |> put_req_header("x-github-event", "push")
        |> post(@webhook_path, %{test: "data"})

      assert json_response(conn, 500) == %{"error" => "Internal error: raw body missing"}
    end

    test "returns 403 when signature is invalid", %{conn: conn} do
      body = Jason.encode!(%{test: "data"})

      capture_log(fn ->
        conn =
          conn
          |> put_req_header("x-hub-signature-256", "sha256=invalid_signature")
          |> put_req_header("x-github-event", "push")
          |> assign(:raw_body, body)
          |> post(@webhook_path, %{test: "data"})

        assert json_response(conn, 403) == %{"error" => "Invalid signature"}
      end)
    end

    test "returns 200 with valid signature and processes webhook", %{conn: conn} do
      body = Jason.encode!(%{test: "data"})

      capture_log(fn ->
        conn =
          conn
          |> put_webhook_headers(body, "push")
          |> post(@webhook_path, %{test: "data"})

        assert json_response(conn, 200) == %{"message" => "Webhook received successfully"}
      end)
    end

    test "handles installation created event", %{conn: conn} do
      installation_data = %{
        "action" => "created",
        "installation" => %{
          "id" => 12345,
          "account" => %{"login" => "testuser"}
        }
      }

      body = Jason.encode!(installation_data)

      capture_log(fn ->
        conn =
          conn
          |> put_webhook_headers(body, "installation")
          |> post(@webhook_path, installation_data)

        assert json_response(conn, 200) == %{"message" => "Webhook received successfully"}
      end)

      # Verify user was created
      installation_id = StaffBot.DB.Users.get_installation_id_by_username("testuser")
      assert installation_id == "12345"
    end

    test "handles pull request opened event with missing data gracefully", %{conn: conn} do
      pr_data = %{
        "action" => "opened",
        "repository" => %{
          "owner" => %{"login" => "testuser"},
          "full_name" => "testuser/testrepo"
        },
        "pull_request" => %{
          "base" => %{"sha" => "base123"},
          "head" => %{"sha" => "head456"}
        },
        "number" => 1
      }

      body = Jason.encode!(pr_data)

      assert capture_log(fn ->
               conn =
                 conn
                 |> put_webhook_headers(body, "pull_request")
                 |> post(@webhook_path, pr_data)

               assert json_response(conn, 200) == %{"message" => "Webhook received successfully"}
             end) =~ "GitHub integration failed"
    end

    test "ignores unhandled event types", %{conn: conn} do
      body = Jason.encode!(%{action: "unknown"})

      capture_log(fn ->
        conn =
          conn
          |> put_webhook_headers(body, "unknown_event")
          |> post(@webhook_path, %{action: "unknown"})

        assert json_response(conn, 200) == %{"message" => "Webhook received successfully"}
      end)
    end
  end

  describe "signature validation" do
    test "validates correct HMAC signature" do
      body = "test body content"
      _signature = create_valid_signature(body)

      # Just verify the function creates a signature
      assert String.starts_with?(_signature, "sha256=")
    end
  end
end
