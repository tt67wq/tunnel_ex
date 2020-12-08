defmodule Server.Utils do
  @moduledoc """
  工具箱
  """

  @doc """
  get current timestamp
  ## Example
  iex> Common.TimeTool.timestamp(:seconds)
  1534466694
  iex> Common.TimeTool.timestamp(:milli_seconds)
  1534466732335
  iex> Common.TimeTool.timestamp(:micro_seconds)
  1534466750683862
  iex> Common.TimeTool.timestamp(:nano_seconds)
  1534466778949821000
  """
  @spec timestamp(atom()) :: integer
  def timestamp(typ \\ :seconds), do: :os.system_time(typ)

  def generete_socket_key, do: Enum.random(0..65535)
end
