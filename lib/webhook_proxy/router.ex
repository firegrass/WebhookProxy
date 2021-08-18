defmodule WebhookProxy.Router do
  use Plug.Router

  @http_client Application.get_env(:webhook_proxy, :httpoison)

  plug(:match)
  plug(:dispatch)

  get "/" do
    send_resp(conn, 200, "Welcome")
  end

  post "/receive/:encoded_url" do
    decode_url(encoded_url)
    |> validate_url()
    |> digest_incoming(conn)
    |> make_outgoing(conn)
  end

  def decode_url(url) do
    url
    |> Base.decode64(ignore: :whitespace)
  end

  def validate_url({:ok, url}) do
    build_regex()
    |> check_url_match(url |> String.trim())
  end

  def validate_url(_) do
    {:err, 400, "Could not base64 decode url in /receive/<url>"}
  end

  def build_regex() do
    Application.fetch_env!(:webhook_proxy, :allowed_urls)
    |> Regex.compile("iu")
  end

  def check_url_match({:ok, regex}, url) do
    case Regex.match?(regex, url) do
      true ->
        {:ok, url}

      false ->
        {:err, 400, "Requested forwarding url did not match allowed expression"}
    end
  end

  def check_url_match({_, _}, _) do
    {:err, 500, "Misconfigured allowed_urls expression"}
  end

  def digest_incoming({:ok, url}, conn) do
    {:ok, body, _} =
      conn
      |> read_body

    case conn.req_headers |> Enum.find({}, fn {k, _v} -> k == "content-type" end) do
      {} ->
        {:err, 415, "Content-type header missing"}

      content_header = {"content-type", "application/json"} ->
        x_headers =
          conn.req_headers
          |> Enum.filter(fn {k, _v} -> String.starts_with?(k, "x-") end)

        {:ok, url, body, [content_header] ++ x_headers}

      {"content-type", _v} ->
        {:err, 415, "Content-type must be application/json"}
    end
  end

  def digest_incoming({:err, status, msg}, _conn) do
    {:err, status, msg}
  end

  def make_outgoing({:ok, url, body, headers}, conn) do
    case @http_client.post(url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: status}} when status >= 200 and status < 300 ->
        respond(conn, 200, "Received with thanks")

      resp ->
        # TODO logger failure
        resp
        |> IO.inspect()

        respond(conn, 502, "Could not forward request")
    end
  end

  def make_outgoing({:err, status, msg}, conn) do
    respond(conn, status, msg)
  end

  def respond(conn, status, msg) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(status, msg)
  end

  match _ do
    send_resp(conn, 404, "Oops!")
  end
end
