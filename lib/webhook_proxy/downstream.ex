defmodule Downstream do
  use HTTPoison.Base

  def process_request_url(url) do
    url
  end

  def process_response_body(body) do
    body
  end
end
