defmodule Boltun do
  @moduledoc """
    Provides macros to define a listener and its callbacks. See the example below

      defmodule TestListener do
        use Boltun, otp_app: :my_app

        listen do
          channel "my_channel", :my_callback
          channel "my_channel", :my_other_callback
          channel "my_other_channel", :my_other_callback
        end

        def my_callback(channel, payload) do
          IO.puts channel
          IO.puts payload
        end
        ...
      end
  """

  defmacro __using__(opts) do
    otp_app = Keyword.fetch!(opts, :otp_app)

    quote do
      import Boltun, only: [channel: 2, channel: 3, channel: 4, listen: 1]
      Module.register_attribute(__MODULE__, :registered_callbacks, [])
      Module.put_attribute(__MODULE__, :registered_callbacks, %{})

      def config() do
        Boltun.get_config(unquote(otp_app), __MODULE__)
      end
    end
  end

  @doc """
    Defines a callback for the given channel, module, function and arguments.
  """
  defmacro channel(channel, module, function, args) do
    quote do
      callback = {unquote(module), unquote(function), unquote(args)}
      channel_cbs = Map.get(@registered_callbacks, unquote(channel), []) ++ [callback]
      Module.put_attribute(__MODULE__, :registered_callbacks, Map.put(@registered_callbacks, unquote(channel), channel_cbs))
    end
  end

  @doc """
    Defines a callback for the given channel, function and optional arguments.
    The callback must be defined in the same module using this macro.
  """
  defmacro channel(channel, function, args \\ []) do
    quote do
      channel(unquote(channel), __MODULE__, unquote(function), unquote(args))
    end
  end

  @doc """
    Defines the listener and its callbacks. Multiple callbacks per channel are supported and they will be invoked in
    in the order in which they appear in this block
  """
  defmacro listen(do: source) do
    quote do
      unquote(source)

      def start_link do
        opts = [
          connection: config(),
          callbacks: @registered_callbacks, name: __MODULE__
        ]
        Boltun.Supervisor.start_link(opts)
      end
    end
  end

  @doc false
  def get_config(otp_app, module) do
    if config = Application.get_env(otp_app, module) do
      parse_ecto_config(config)
    else
      raise ArgumentError, "configuration for #{inspect module} not specified in #{inspect otp_app}"
    end
  end

  @doc """
    Parses ecto config to regular config
  """
  def parse_ecto_config(ecto: ecto_url) when is_binary(ecto_url) do
    case Regex.run(~r/ecto:\/\/(.+):(.+)@(.+)\/(.+)$/, ecto_url) do
      [_, username, password, hostname, database] ->
        [
          database: database,
          username: username,
          password: password,
          hostname: hostname
        ]
      _ ->
        nil
    end
  end
  
  def parse_ecto_config(config) do
    config
  end
end
