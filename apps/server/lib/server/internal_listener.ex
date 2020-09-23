defmodule Server.InternalListener do
  @moduledoc """
  内部监听
  """
  require Logger
  use GenServer
  alias Server.{InternalWorker}

  defp server_port, do: Application.get_env(:server, :port)

  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def init(_opts) do
    port = server_port()
    {:ok, acceptor} = :gen_tcp.listen(port, [:binary, active: false, reuseaddr: true, packet: 2])
    send(self(), :accept)

    Logger.info("Accepting connection on port #{port}...")
    {:ok, %{acceptor: acceptor}}
  end

  def handle_info(:accept, %{acceptor: acceptor} = state) do
    {:ok, sock} = :gen_tcp.accept(acceptor)

    # 启动一个本地数据处理进程
    {:ok, pid} = GenServer.start_link(InternalWorker, socket: sock)

    :gen_tcp.controlling_process(sock, pid)

    send(self(), :accept)
    {:noreply, state}
  end

  # ignore msg
  def handle_info(_, state) do
    {:noreply, state}
  end
end
