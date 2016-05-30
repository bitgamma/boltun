defmodule Boltun.Connection do
  @moduledoc false

  @doc false
  def start_link(opts, name) do
    res = {:ok, pid} = Postgrex.Notifications.start_link(opts)
    Process.register pid, name
    res
  end
end
