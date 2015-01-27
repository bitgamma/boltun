defmodule Boltun.CallbacksAgent do
  @moduledoc """
    Stores the callback to be executed by a listener. The functions defined here should only be
    invoked by a listener, since it also takes care of sending the LISTEN/UNLISTEN commands to the connection.
  """

  @doc "Starts the callback agent"
  def start_link(initial_callbacks, opts) do
    Agent.start_link(fn -> Enum.into(initial_callbacks, HashDict.new) end, opts)
  end

  @doc "Returns the list of channels to monitor"
  def channels(agent) do
    Agent.get(agent, &Dict.keys(&1))    
  end

  @doc "Returns all callbacks for the given channel"
  def callbacks_for_channel(agent, channel) do
    Agent.get(agent, &Dict.get(&1, channel))
  end

  @doc "Adds a callback for the given channel"
  def add_to_channel(agent, channel, {_module, _function, _args} = value) do
    Agent.update(agent, fn callbacks -> 
      channel_cbs = Dict.get(callbacks, channel, []) ++ [value]
      Dict.put(callbacks, channel, channel_cbs)
    end)
  end

  @doc "Removes all callbacks for the given channel"
  def remove_channel(agent, channel) do
    Agent.get_and_update(agent, &Dict.delete(&1, channel))
  end
end