defmodule Seecure.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SeecureWeb.Telemetry,
      Seecure.Repo,
      {DNSCluster, query: Application.get_env(:seecure, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Seecure.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Seecure.Finch},
      # Start a worker by calling: Seecure.Worker.start_link(arg)
      # {Seecure.Worker, arg},
      # Start to serve requests, typically the last entry
      SeecureWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Seecure.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SeecureWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
