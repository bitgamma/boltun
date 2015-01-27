defmodule Boltun.Supervisor do
  use Supervisor

  @doc "Starts the Boltun supervision tree. Options must contain the connection parameters and the initial callbacks"
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  @doc false
  def init(opts) do
    name = Keyword.fetch!(opts, :name)
    callbacks_agent = Module.concat(name, "CallbacksAgent")
    connection = Module.concat(name, "Connection")
    listener = Module.concat(name, "Listener")

    children = [
      worker(Boltun.CallbacksAgent, [Keyword.fetch!(opts, :callbacks), [name: callbacks_agent]]),
      worker(Boltun.Connection, [Keyword.fetch!(opts, :connection), connection]),
      worker(Boltun.Listener, [[connection: connection, callbacks_agent: callbacks_agent], [name: listener]])
    ]
    supervise(children, strategy: :rest_for_one)
  end
end