defmodule Server.ExternalListener do
  @moduledoc """
  外部监听
  """

  require Logger
  use GenServer
  alias Server.{ExternalWorker, SocketStore, Utils}

  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc """
  nat 示例
  %{
    "from"=> "localhost:8080"
    "to"=> "192.168.10.101:80"
  }
  """
  def init(nat: nat) do
    [_, port_str] = nat |> Map.get("from") |> String.split(":")
    port = String.to_integer(port_str)

    {:ok, acceptor} = :gen_tcp.listen(port, [:binary, active: false, reuseaddr: true])
    send(self(), :accept)
    Logger.info("Accepting connection on port #{port}...")

    {:ok, %{acceptor: acceptor, nat: nat, port: port}}
  end

  def handle_info(:accept, %{acceptor: acceptor, port: port} = state) do
    {:ok, sock} = :gen_tcp.accept(acceptor)
    Logger.info("new connection established from port #{port}")

    sock_key = Utils.generete_socket_key()

    # 创建一个worker 来处理外部数据
    {:ok, pid} = GenServer.start_link(ExternalWorker, socket: sock, nat: state.nat, key: sock_key)
    :gen_tcp.controlling_process(sock, pid)

    # 注册至 key => socket 仓库
    SocketStore.add_socket(sock_key, pid)

    send(self(), :accept)
    {:noreply, state}
  end

  # ignore msg
  def handle_info(_, state) do
    {:noreply, state}
  end
end
