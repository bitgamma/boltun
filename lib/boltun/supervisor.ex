defmodule Boltun.Supervisor do
  use Supervisor

  @doc """
  Starts the Boltun supervision tree. The options are:
  * `connection`: the connection parameters
  * `name`: the base name to register the process.
  * `callbacks`: the initial callbacks (optional)

  The supervisor will register each started process by using the provided name and concatenating
  a dot and the following suffixes:
  * `CallbacksAgent` the agent where the callbacks are stored
  * `Connection` the connection to the database
  * `Listener` the actual listener. You can use this to manage active callbacks
  """
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
      worker(Boltun.CallbacksAgent, [Keyword.get(opts, :callbacks, []), [name: callbacks_agent]]),
      worker(Boltun.Connection, [Keyword.fetch!(opts, :connection), connection]),
      worker(Boltun.Listener, [[connection: connection, callbacks_agent: callbacks_agent], [name: listener]])
    ]
    supervise(children, strategy: :rest_for_one)
  end
end
