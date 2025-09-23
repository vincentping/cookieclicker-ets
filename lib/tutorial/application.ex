defmodule Tutorial.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TutorialWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:tutorial, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Tutorial.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Tutorial.Finch},
      # Start a worker by calling: Tutorial.Worker.start_link(arg)
      # {Tutorial.Worker, arg},
      # Start to serve requests, typically the last entry
      TutorialWeb.Endpoint
    ]

    # 初始化 ETS 表用于存储全局计数器和在线用户数
    :ets.new(:cookies_counter, [:set, :public, :named_table])

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Tutorial.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TutorialWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
