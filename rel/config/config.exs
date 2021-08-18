use Mix.Config

config :webhook_proxy, :allowed_urls, System.fetch_env!("ALLOWED_URLS")
