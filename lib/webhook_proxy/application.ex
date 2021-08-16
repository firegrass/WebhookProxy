defmodule WebhookProxy.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: WebhookProxy.Worker.start_link(arg)
      # {WebhookProxy.Worker, arg}
      {Plug.Cowboy, scheme: :http, plug: WebhookProxy.Router, options: [port: 8080]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: WebhookProxy.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
