defmodule Boltun do
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

  defmacro channel(channel, module, function, args) do
    quote do
      callback = {unquote(module), unquote(function), unquote(args)}
      channel_cbs = Dict.get(@registered_callbacks, unquote(channel), []) ++ [callback]
      Module.put_attribute(__MODULE__, :registered_callbacks, Dict.put(@registered_callbacks, unquote(channel), channel_cbs))
    end
  end

  defmacro channel(channel, function, args \\ []) do
    quote do
      channel(unquote(channel), __MODULE__, unquote(function), unquote(args))
    end
  end

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

  def get_config(otp_app, module) do
    if config = Application.get_env(otp_app, module) do
      config
    else
      raise ArgumentError, "configuration for #{inspect module} not specified in #{inspect otp_app}"
    end
  end
end
