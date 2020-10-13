defmodule Server.ExternalWorker do
  @moduledoc """
  数据处理进程
  """

  use GenServer
  require Logger
  alias Server.{InternalWorker, SocketStore, IPSocketStore, Typespec}

  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def send_message(pid, message), do: GenServer.cast(pid, {:message, message})

  @spec init(socket: Typespec.socket(), nat: map(), key: Typespec.sock_key()) :: {:ok, pid()}
  def init(socket: socket, nat: nat, key: key) do
    [client_ip_raw, client_port] =
      nat
      |> Map.get("to")
      |> String.split(":")

    {:ok, {ip0, ip1, ip2, ip3}} = client_ip_raw |> to_charlist() |> :inet.parse_address()

    :inet.setopts(socket, active: false)
    send(self(), :tcp_connection_req)

    {:ok,
     %{
       socket: socket,
       key: key,
       client_ip: <<ip0, ip1, ip2, ip3>>,
       client_port: String.to_integer(client_port),
       status: 0,
       buffer: :queue.new()
     }}
  end

  def handle_info(:tcp_connection_req, state) do
    Logger.info("send tcp connecntion request")

    send_msg(state.client_ip, <<0x09, 0x03, state.key::16, state.client_port::16>>)
    :inet.setopts(state.socket, active: true)
    {:noreply, Map.put(state, :status, 1)}
  end

  def handle_info(:tcp_connection_set, state) do
    Logger.info("recv tcp connecntion finished")

    # send all buffer to client
    flush_buffer(state.buffer, state.key, state.client_ip)

    new_state =
      state
      |> Map.put(:status, 2)
      |> Map.put(:buffer, :queue.new())

    {:noreply, new_state}
  end

  def handle_info({:tcp_closed, _}, state), do: {:stop, :normal, state}
  def handle_info({:tcp_error, _}, state), do: {:stop, :normal, state}

  def handle_info({:tcp, _, data}, state) do
    Logger.info("external recv => #{inspect(data)}")

    new_state =
      case state.status do
        2 ->
          # already set
          send_msg(state.client_ip, <<state.key::16>> <> data)
          state

        _ ->
          # not set, go to buffer
          Map.put(state, :buffer, :queue.in(data, state.buffer))
      end

    {:noreply, new_state}
  end

  def handle_cast({:message, message}, state) do
    Logger.debug("external send: #{inspect(message)}")
    :gen_tcp.send(state.socket, message)
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

    send_msg(state.client_ip, <<0x09, 0x04, state.key::16>>)
    SocketStore.rm_socket(state.key)
  end

  defp send_msg(ip, msg) do
    case IPSocketStore.get_socket(ip) do
      nil ->
        Logger.warn("no socket avaiable")
        {:error, "no socket avaiable"}

      pid ->
        InternalWorker.send_message(pid, msg)
    end
  end

  defp flush_buffer(buffer, key, ip) do
    buffer
    |> :queue.out()
    |> case do
      {{:value, msg}, buf} ->
        send_msg(ip, <<key::16>> <> msg)
        flush_buffer(buf, key, ip)

      {:empty, _} ->
        nil
    end
  end
end
