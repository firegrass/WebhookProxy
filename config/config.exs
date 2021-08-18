use Mix.Config

config :webhook_proxy, :httpoison, Downstream

# config :webhook_proxy, :allowed_urls, "http://localhost:8081/.*"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
