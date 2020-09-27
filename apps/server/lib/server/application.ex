defmodule Server.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  defp load_cfg() do
    cfg =
      :server
      |> Application.get_env(:cfg_path)
      |> Path.expand()
      |> File.read!()
      |> YamlElixir.read_from_string!()

    server_cfg = Map.fetch!(cfg, "server")
    nat_cfg = Map.fetch!(cfg, "nat")

    Application.put_env(:server, :port, Map.get(server_cfg, "port"))
    Application.put_env(:server, :nat, nat_cfg)
  end

  def start(_type, _args) do
    load_cfg()

    children = [
      # Starts a worker by calling: Server.Worker.start_link(arg)

      Server.IPSocketStore,
      Server.SocketStore,
      Server.InternalListener
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Server.Supervisor]
    Supervisor.start_link(children ++ get_external_listeners(), opts)
  end

  # 外部监听实例
  defp get_external_listeners() do
    :server
    |> Application.get_env(:nat)
    |> Enum.map(fn x ->
      Supervisor.child_spec(
        {Server.ExternalListener, [nat: x, name: Map.get(x, "name") |> String.to_atom()]},
        id: Map.get(x, "name") |> String.to_atom()
      )
    end)
  end
end
