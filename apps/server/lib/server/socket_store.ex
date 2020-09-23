defmodule Server.SocketStore do
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def get_socket(sock_key) do
    __MODULE__
    |> Agent.get(& &1)
    |> Map.get(sock_key)
  end

  def add_socket(sock_key, pid), do: Agent.update(__MODULE__, fn x -> Map.put(x, sock_key, pid) end)
  def rm_socket(sock_key), do: Agent.update(__MODULE__, fn x -> Map.delete(x, sock_key) end)
end

defmodule Server.IPSocketStore do
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def get_socket(ip) do
    __MODULE__
    |> Agent.get(& &1)
    |> Map.get(ip)
  end

  def add_socket(ip, pid), do: Agent.update(__MODULE__, fn x -> Map.put(x, ip, pid) end)
  def rm_socket(ip), do: Agent.update(__MODULE__, fn x -> Map.delete(x, ip) end)
end
