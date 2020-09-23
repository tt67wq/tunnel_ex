defmodule Client.SocketStore do
  @moduledoc """
  用于存储socket的全局变量

  key => socket pid
  """
  use Agent

  def start_link(_opts), do: Agent.start_link(fn -> %{} end, name: __MODULE__)

  @doc """
  get socket pid from store

  * `key`     - get pid from store

  ## Examples

  iex> Client.SocketStore.get_socket(1235)
  some pid
  """
  @spec get_socket(integer()) :: pid()
  def get_socket(key) do
    __MODULE__
    |> Agent.get(& &1)
    |> Map.get(key)
  end

  @spec add_socket(integer(), pid()) :: :ok
  def add_socket(key, pid), do: Agent.update(__MODULE__, fn x -> Map.put(x, key, pid) end)

  @spec rm_socket(integer()) :: :ok
  def rm_socket(key), do: Agent.update(__MODULE__, fn x -> Map.delete(x, key) end)
end
