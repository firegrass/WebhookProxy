defmodule WebhookProxy.RouterTest do
  use ExUnit.Case
  use Plug.Test
  alias WebhookProxy.Router

  import Mox

  @opts Router.init([])

  test "returns welcome" do
    conn =
      :get
      |> conn("/", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "process webhook" do
    WebhookProxy.MockHTTPoison
    |> expect(:post, fn "http://test_server:3000/webhook",
                        _,
                        [{"content-type", "application/json"}] ->
      {:ok,
       %HTTPoison.Response{
         body: %{status: "processed"} |> Jason.encode!(),
         status_code: 200
       }}
    end)

    conn =
      :post
      |> conn("/receive/aHR0cDovL3Rlc3Rfc2VydmVyOjMwMDAvd2ViaG9vawo=", "")
      |> put_req_header("content-type", "application/json")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == "Received with thanks"
  end

  test "Strip newline from base64 decoded url if needed" do
    url = "http://test_server:3000/webhook"

    url_base64 =
      (url <> "\n")
      |> Base.encode64()
      |> String.trim()

    WebhookProxy.MockHTTPoison
    |> expect(:post, fn ^url, _, [{"content-type", "application/json"}] ->
      {:ok,
       %HTTPoison.Response{
         body: %{status: "processed"} |> Jason.encode!(),
         status_code: 200
       }}
    end)

    conn =
      :post
      |> conn("/receive/#{url_base64}", "")
      |> put_req_header("content-type", "application/json")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == "Received with thanks"
  end

  test "forward x- headers" do
    WebhookProxy.MockHTTPoison
    |> expect(:post, fn "http://test_server:3000/webhook",
                        _,
                        [{"content-type", "application/json"}, {"x-test", "test"}] ->
      {:ok,
       %HTTPoison.Response{
         body: %{status: "processed"} |> Jason.encode!(),
         status_code: 200
       }}
    end)

    conn =
      :post
      |> conn("/receive/aHR0cDovL3Rlc3Rfc2VydmVyOjMwMDAvd2ViaG9vawo=", "")
      |> put_req_header("content-type", "application/json")
      |> put_req_header("x-test", "test")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == "Received with thanks"
  end

  test "don't forward non application/json" do
    conn =
      :post
      |> conn("/receive/aHR0cDovL3Rlc3Rfc2VydmVyOjMwMDAvd2ViaG9vawo=", "")
      |> put_req_header("content-type", "application/xml")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 415
    assert conn.resp_body == "Content-type must be application/json"
  end

  test "return 5xx if downstream webhook fails" do
    WebhookProxy.MockHTTPoison
    |> expect(:post, fn "http://test_server:3000/webhook",
                        _,
                        [{"content-type", "application/json"}] ->
      {:ok,
       %HTTPoison.Response{
         body: %{status: "processed"} |> Jason.encode!(),
         status_code: 404
       }}
    end)

    conn =
      :post
      |> conn("/receive/aHR0cDovL3Rlc3Rfc2VydmVyOjMwMDAvd2ViaG9vawo=", "")
      |> put_req_header("content-type", "application/json")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 502
    assert conn.resp_body == "Could not forward request"
  end

  test "honor url allow list" do
    url = "http://invalid_server:3000/webhook"

    url_base64 =
      url
      |> Base.encode64()
      |> String.trim()

    conn =
      :post
      |> conn("/receive/#{url_base64}", "")
      |> put_req_header("content-type", "application/json")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 400
    assert conn.resp_body == "Requested forwarding url did not match allowed expression"
  end

  test "returns 404" do
    conn =
      :get
      |> conn("/missing", "")
      |> Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 404
  end
end
