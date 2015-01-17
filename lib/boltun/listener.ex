defmodule Boltun.Listener do
  @moduledoc """
    Listens to Postgrex notifications and invokes the registed callbacks.
  """

  @doc """
    Starts a listener. Expects a keyword list with the following parameters
    * `:connection` => pid or name of the connection to the database
    * `:callbacks_agent` => pid or name of the agent keeping track of the callbacks  
    * `:name` => the name to register (optional)
  """
  def start_link(opts) do
    res = {:ok, pid} = Task.start_link(fn -> init(opts) end)
    register_name(pid, Keyword.get(opts, :name))
    res
  end

  @doc "Stops this listener and deregisters all channels"
  def stop(listener) do
    send listener, :stop
  end

  @doc "Adds a callback to the given channel"
  def add_callback(listener, channel, {_module, _function, _args} = value) do
    send listener, {:add_callback, channel, value}
  end

  @doc "Removes all callbacks for the given channel"
  def remove_channel(listener, channel) do
    send listener, {:remove_channel, channel}
  end

  defp register_name(_pid, nil), do: true
  defp register_name(pid, name), do: Process.register(pid, name)

  defp init(opts) do
    conn = Keyword.fetch!(opts, :connection)
    cba = Keyword.fetch!(opts, :callbacks_agent)
    
    for channel <- Boltun.CallbacksAgent.channels(cba) do
      register_channel(conn, channel)
    end

    listen(conn, cba)
  end

  defp listen(conn, cba) do
    receive do
      {:notification, _, {:msg_notify, _, channel, payload}} -> execute_callbacks(cba, channel, payload)
      {:add_callback, channel, value} -> register_callback(conn, cba, channel, value)
      {:remove_channel, channel} -> deregister_callback(conn, cba, channel)
      :stop -> die(conn, cba)
      msg -> raise "Unexpected message #{msg}"
    end

    listen(conn, cba)
  end

  defp register_callback(conn, cba, channel, value) do
    Boltun.CallbacksAgent.add_to_channel(cba, channel, value)
    register_channel(conn, channel)
  end

  defp deregister_callback(conn, cba, channel) do
    Boltun.CallbacksAgent.remove_channel(cba, channel)
    deregister_channel(conn, channel)
  end

  defp register_channel(conn, channel), do: Postgrex.Connection.listen(conn, channel)
  defp deregister_channel(conn, channel), do: Postgrex.Connection.unlisten(conn, channel)

  defp execute_callbacks(cba, channel, payload) do
    for {module, function, args} <- Boltun.CallbacksAgent.callbacks_for_channel(cba, channel) do
      apply(module, function, [channel | [payload | args]])
    end
  end

  defp die(conn, cba) do
    for channel <- Boltun.CallbacksAgent.channels(cba) do
      deregister_channel(conn, channel)
    end  

    Process.exit(self(), :normal)
  end
end