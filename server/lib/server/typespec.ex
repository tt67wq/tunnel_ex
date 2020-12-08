defmodule Server.Typespec do
  @moduledoc """
  类型枚举
  """
  @type socket :: pid() | nil
  @type sock_key :: integer()
  @type ip :: binary()
end
