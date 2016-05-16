defmodule Boltun.Listener do
  use GenServer

  @moduledoc """
    Listens to Postgrex notifications and invokes the registed callbacks.
  """

  @doc """
    Starts a listener. Expects a keyword list with the following parameters
    * `:connection` => pid or name of the connection to the database
    * `:callbacks_agent` => pid or name of the agent keeping track of the callbacks  
    
    and a keyword list with GenServer specific options, like `:name`.
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
    
    state = %{connection: conn, callbacks_agent: cba, listeners: %{}}
    {:ok, Enum.reduce(Boltun.CallbacksAgent.channels(cba), state, &register_channel(&2, &1))}
  end

  def handle_call(:stop, _from, %{callbacks_agent: cba} = state) do
    state = Enum.reduce(Boltun.CallbacksAgent.channels(cba), state, &deregister_channel(&2, &1))
    {:stop, :normal, :ok, state}
  end
  def handle_call({:add_callback, channel, value}, _from, state) do
    state = register_callback(state, channel, value)
    {:reply, :ok, state}
  end
  def handle_call({:remove_channel, channel}, _from, state) do
    state = deregister_callback(state, channel)
    {:reply, :ok, state}
  end

  def handle_info({:notification, _, _, channel, payload}, %{callbacks_agent: cba} = state) do
    execute_callbacks(cba, channel, payload)
    {:noreply, state}
  end

  defp register_callback(%{callbacks_agent: cba} = state, channel, value) do
    Boltun.CallbacksAgent.add_to_channel(cba, channel, value)
    register_channel(state, channel)
  end

  defp deregister_callback(%{callbacks_agent: cba} = state, channel) do
    Boltun.CallbacksAgent.remove_channel(cba, channel)
    deregister_channel(state, channel)
  end

  defp register_channel(%{connection: conn, listeners: refs} = state, channel) do
    if not Map.has_key?(refs, channel) do
      {:ok, ref} = Postgrex.Notifications.listen(conn, channel)
      refs = Map.put(refs, channel, ref)
      %{ state | listeners: refs}
    else
      state
    end
  end

  defp deregister_channel(%{connection: conn, listeners: refs} = state, channel) do
    {ref, refs} = Map.pop(refs, channel)
    Postgrex.Notifications.unlisten(conn, ref)
    %{ state | listeners: refs}
  end

  defp execute_callbacks(cba, channel, payload) do
    for {module, function, args} <- Boltun.CallbacksAgent.callbacks_for_channel(cba, channel) do
      apply(module, function, [channel | [payload | args]])
    end
  end
end
