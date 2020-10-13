defmodule Server.InternalWorker do
  @moduledoc """
  内部数据交互进程
  """
  use GenServer
  require Logger
  alias Server.{ExternalWorker, SocketStore, IPSocketStore}

  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def send_message(pid, message), do: GenServer.cast(pid, {:message, message})

  def init(socket: socket) do
    :inet.setopts(socket, active: true)
    {:ok, %{socket: socket}}
  end

  def handle_info({:tcp_closed, _}, state), do: {:stop, :normal, state}
  def handle_info({:tcp_error, _}, state), do: {:stop, :normal, state}

  def handle_info({:tcp, socket, <<0x09::8, 0x01::8, ip::32>> = data}, state) do
    Logger.info("internal recv => #{inspect(data)}")
    IPSocketStore.add_socket(<<ip::32>>, self())
    # handshake
    :gen_tcp.send(socket, <<0x09, 0x02>>)
    {:noreply, Map.put(state, :ip, <<ip::32>>)}
  end

  def handle_info({:tcp, _socket, <<key::16, real_data::binary>> = data}, state) do
    Logger.info("internal recv => #{inspect(data)}")

    case SocketStore.get_socket(key) do
      nil ->
        # no socket, error
        Logger.warn("no external socket")

      pid ->
        ExternalWorker.send_message(pid, <<real_data::binary>>)
    end

    {:noreply, state}
  end

  # 流量发向本地server
  def handle_cast({:message, message}, state) do
    Logger.debug("internal send: #{inspect(message)}")
    :ok = :gen_tcp.send(state.socket, message)
    {:noreply, state}
  end

  # handle termination
  def terminate(reason, state) do
    Logger.info("terminating")
    cleanup(reason, state)
    state
  end

  defp cleanup(_reason, state) do
    # Cleanup whatever you need cleaned up
    IPSocketStore.rm_socket(state.ip)
  end
end
