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
         {:ok, sock} <- :gen_tcp.connect(ip, port, [:binary, active: true, packet: 2]),
         localhost <- client_cfg(),
         {:ok, {ip0, ip1, ip2, ip3}} <- localhost |> to_charlist |> :inet.parse_address() do
      # handshake
      :gen_tcp.send(sock, <<0x09, 0x01, ip0, ip1, ip2, ip3>>)
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

  def handle_info({:tcp, _socket, <<0x09, 0x02>>}, state) do
    # handshake finished
    Logger.info("handshake finished")
    {:noreply, state}
  end

  # 只建立连接
  def handle_info({:tcp, socket, <<0x09, 0x03, key::16, client_port::16>>}, state) do
    Logger.debug("selector recv tcp connection request")
    create_local_conn(key, client_port)
    :gen_tcp.send(socket, <<0x09, 0x03, key::16>>)
    {:noreply, state}
  end

  # 断开连接
  def handle_info({:tcp, _, <<0x09, 0x04, key::16>>}, state) do
    Logger.debug("selector recv tcp close request")

    # close socket
    SocketStore.get_socket(key)
    |> case do
      nil ->
        nil

      pid ->
        SocketStore.rm_socket(key)
        send(pid, {:tcp_closed, :normal})
    end

    {:noreply, state}
  end

  def handle_info({:tcp, _socket, data}, state) do
    Logger.debug("selector recv => #{inspect(data)}")
    <<key::16, real_data::binary>> = data

    key
    |> SocketStore.get_socket()
    |> case do
      nil ->
        Logger.error("no connection for key #{key}")

      pid ->
        Worker.send_message(pid, <<real_data::binary>>)
    end

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

  defp create_local_conn(key, port) do
    with {:ok, sock} <- :gen_tcp.connect('localhost', port, [:binary, active: true]),
         {:ok, pid} <- GenServer.start_link(Worker, socket: sock, key: key, selector: self()),
         :ok <- :gen_tcp.controlling_process(sock, pid) do
      Logger.info("establish a new connection to localhost:#{port}")
      SocketStore.add_socket(key, pid)
    else
      reason ->
        Logger.info("connect to localhost:#{port} failed => #{inspect(reason)}")
        :error
    end
  end
end
