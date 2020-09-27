defmodule Client.Selector do
  @moduledoc """
  穿透的本地转发

  协议 << local_port, server_port, data...>>
  """

  require Logger
  use GenServer
  alias Client.{Worker, SocketStore}

  @spec send_message(pid(), String.t()) :: :ok
  def send_message(pid, message), do: GenServer.cast(pid, {:message, message})

  defp server_cfg do
    cfg = Application.get_env(:client, :server_cfg)
    {Keyword.fetch!(cfg, :host), Keyword.fetch!(cfg, :port)}
  end

  defp client_cfg do
    cfg = Application.get_env(:client, :client_cfg)
    Keyword.fetch!(cfg, :host)
  end

  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def init(_opt) do
    send(self(), :connect)
    {:ok, %{socket: nil}}
  end

  def handle_info(:connect, state) do
    {host, port} = server_cfg()
    Logger.info("Connecting to #{host}:#{port}")

    with {:ok, ip} <- host |> to_charlist |> :inet.parse_address(),
         {:ok, sock} <- :gen_tcp.connect(ip, port, [:binary, active: 1000, packet: 2]),
         localhost <- client_cfg(),
         {:ok, {ip0, ip1, ip2, ip3}} <- localhost |> to_charlist |> :inet.parse_address() do
      # handshake
      :gen_tcp.send(sock, <<0x09, 0x01, ip0, ip1, ip2, ip3>>)
      Process.send_after(self(), :reset_active, 1000)
      {:noreply, Map.put(state, :socket, sock)}
    else
      {:error, reason} ->
        Logger.warn("reason -> #{inspect(reason)}")
        Process.send_after(self(), :connect, 1000)
        {:noreply, state}

      _ ->
        {:stop, :normal, state}
    end
  end

  # 设置流量限额
  def handle_info(:reset_active, state) do
    :inet.setopts(state.socket, active: 1000)
    Process.send_after(self(), :reset_active, 1000)
    {:noreply, state}
  end

  def handle_info({:tcp, _socket, <<0x09, 0x02>>}, state) do
    # handshake finished
    Logger.info("handshake finished")
    {:noreply, state}
  end

  # 只建立连接
  def handle_info({:tcp, _socket, <<0x09, 0x03, key::16, client_port::16>>}, state) do
    Logger.debug("selector recv tcp connection request")
    get_or_create_local_socket(key, client_port)
    {:noreply, state}
  end

  def handle_info({:tcp, _socket, data}, state) do
    Logger.debug("selector recv => #{inspect(data)}")
    <<key::16, client_port::16, real_data::binary>> = data
    {:ok, pid} = get_or_create_local_socket(key, client_port)

    Worker.send_message(pid, <<real_data::binary>>)

    {:noreply, state}
  end

  def handle_info({:tcp_closed, _}, state) do
    Logger.warn("selector socket closed")
    Process.send_after(self(), :connect, 1000)
    {:noreply, state}
  end

  def handle_info({:tcp_error, _}, state) do
    Logger.warn("selector socket error")
    {:stop, :normal, state}
  end

  def handle_cast({:message, message}, state) do
    Logger.debug("selector send: #{inspect(message)}")
    :ok = :gen_tcp.send(state.socket, message)
    {:noreply, state}
  end

  defp get_or_create_local_socket(key, local_port) do
    case SocketStore.get_socket(key) do
      nil ->
        # no existing socket, establish a new one
        {:ok, sock} = :gen_tcp.connect('localhost', local_port, [:binary, active: true])

        Logger.info("establish a new connection to localhost:#{local_port}")

        {:ok, pid} =
          GenServer.start_link(Worker,
            socket: sock,
            key: key,
            selector: self()
          )

        :gen_tcp.controlling_process(sock, pid)
        SocketStore.add_socket(key, pid)
        {:ok, pid}

      pid ->
        Logger.debug("existing pid #{inspect(pid)}")
        {:ok, pid}
    end
  end
end
