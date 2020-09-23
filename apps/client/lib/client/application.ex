defmodule Client.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  defp load_cfg() do
    cfg =
      Application.get_env(:client, :cfg_path) |> File.read!() |> YamlElixir.read_from_string!()

    client_cfg = Map.get(cfg, "client")
    server_cfg = Map.get(cfg, "server")
    logger_cfg = Map.get(cfg, "logger")

    Application.put_env(:client, :client_cfg, host: Map.get(client_cfg, "host"))

    Application.put_env(:client, :server_cfg,
      host: Map.get(server_cfg, "host"),
      port: Map.get(server_cfg, "port")
    )

    Application.put_env(:logger, :level, String.to_atom(Map.get(logger_cfg, "level")))
  end

  def start(_type, _args) do
    load_cfg()
    IO.puts("============== config ===============")
    IO.inspect(Application.get_all_env(:client))
    IO.puts("============== config ===============")

    children = [
      # Starts a worker by calling: Client.Worker.start_link(arg)
      # {Client.Worker, arg}
      Client.SocketStore,
      Client.Selector
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Client.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
