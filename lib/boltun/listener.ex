defmodule Boltun.Listener do
  use GenServer

  @moduledoc """
    Listens to Postgrex notifications and invokes the registed callbacks.
  """

  @doc """
    Starts a listener. Expects a keyword list with the following parameters
    * `:connection` => pid or name of the connection to the database
    * `:callbacks_agent` => pid or name of the agent keeping track of the callbacks  
    
    and a keyword list with GenServer specific options, like `name`.
  """
  def start_link(opts, server_opts) do
    GenServer.start_link(__MODULE__, opts, server_opts)
  end

  @doc "Stops this listener and deregisters all channels"
  def stop(listener) do
    GenServer.call(listener, :stop)
  end

  @doc "Adds a callback to the given channel"
  def add_callback(listener, channel, {_module, _function, _args} = value) do
    GenServer.call(listener, {:add_callback, channel, value})
  end

  @doc "Removes all callbacks for the given channel"
  def remove_channel(listener, channel) do
    GenServer.call(listener, {:remove_channel, channel})
  end

  def init(opts) do
    conn = Keyword.fetch!(opts, :connection)
    cba = Keyword.fetch!(opts, :callbacks_agent)
    
    for channel <- Boltun.CallbacksAgent.channels(cba) do
      register_channel(conn, channel)
    end

    {:ok, %{connection: conn, callbacks_agent: cba}}
  end

  def handle_call(:stop, _from, %{connection: conn, callbacks_agent: cba} = state) do
    for channel <- Boltun.CallbacksAgent.channels(cba) do
      deregister_channel(conn, channel)
    end  

    {:stop, :normal, :ok, state}
  end
  def handle_call({:add_callback, channel, value}, _from, %{connection: conn, callbacks_agent: cba} = state) do
    register_callback(conn, cba, channel, value)
    {:reply, :ok, state}
  end
  def handle_call({:remove_channel, channel}, _from, %{connection: conn, callbacks_agent: cba} = state) do
    deregister_callback(conn, cba, channel)
    {:reply, :ok, state}
  end

  def handle_info({:notification, _, _, channel, payload}, %{callbacks_agent: cba} = state) do
    execute_callbacks(cba, channel, payload)
    {:noreply, state}
  end

  defp register_callback(conn, cba, channel, value) do
    Boltun.CallbacksAgent.add_to_channel(cba, channel, value)
    register_channel(conn, channel)
  end

  defp deregister_callback(conn, cba, channel) do
    deregister_channel(conn, channel)
    Boltun.CallbacksAgent.remove_channel(cba, channel)
  end

  defp register_channel(conn, channel), do: Postgrex.Connection.listen(conn, channel)
  defp deregister_channel(conn, channel), do: Postgrex.Connection.unlisten(conn, channel)

  defp execute_callbacks(cba, channel, payload) do
    for {module, function, args} <- Boltun.CallbacksAgent.callbacks_for_channel(cba, channel) do
      apply(module, function, [channel | [payload | args]])
    end
  end
end