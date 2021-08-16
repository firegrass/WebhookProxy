use Mix.Config

config :webhook_proxy, :httpoison, WebhookProxy.MockHTTPoison

config :webhook_proxy, :allowed_urls, "http://test_server:3000/.*"

# Mox.defmock(WebhookProxy.MockHTTPoison, for: HTTPoison.Base)
