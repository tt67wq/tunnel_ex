defmodule Common.Helper do
  @moduledoc """
  工具函数
  """
  defmacro __using__(_opts) do
    quote do
      import EtaQueue.Helpers
    end
  end

  defmacro defbang({name, _, args}) do
    args = if is_list(args), do: args, else: []

    quote bind_quoted: [name: Macro.escape(name), args: Macro.escape(args)] do
      def unquote((to_string(name) <> "!") |> String.to_atom())(unquote_splicing(args)) do
        case unquote(name)(unquote_splicing(args)) do
          :ok ->
            :ok

          {:ok, result} ->
            result

          {:error, reason} ->
            {:error, reason}
        end
      end
    end
  end

end
