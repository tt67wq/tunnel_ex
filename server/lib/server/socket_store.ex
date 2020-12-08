defmodule Server.SocketStore do
  use Agent
  alias Server.Typespec

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  @spec get_socket(Typespec.sock_key()) :: Typespec.socket()
  def get_socket(sock_key) do
    __MODULE__
    |> Agent.get(& &1)
    |> Map.get(sock_key)
  end

  @spec add_socket(Typespec.sock_key(), Typespec.socket()) :: :ok
  def add_socket(sock_key, pid),
    do: Agent.update(__MODULE__, fn x -> Map.put(x, sock_key, pid) end)

  @spec rm_socket(Typespec.sock_key()) :: :ok
  def rm_socket(sock_key), do: Agent.update(__MODULE__, fn x -> Map.delete(x, sock_key) end)
end

defmodule Server.IPSocketStore do
  use Agent
  alias Server.Typespec

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  @spec get_socket(Typespec.ip()) :: Typespec.socket()
  def get_socket(ip) do
    __MODULE__
    |> Agent.get(& &1)
    |> Map.get(ip)
    |> (fn
          nil -> nil
          socks -> Enum.random(socks)
        end).()
  end

  @spec add_socket(Typespec.ip(), Typespec.socket()) :: :ok
  def add_socket(ip, pid),
    do: Agent.update(__MODULE__, fn x -> Map.update(x, ip, [pid], &[pid | &1]) end)

  @spec rm_socket(Typespec.ip()) :: :ok
  def rm_socket(ip), do: Agent.update(__MODULE__, fn x -> Map.delete(x, ip) end)
end
