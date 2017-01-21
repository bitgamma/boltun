# Boltun

Boltun simplifies handling of the LISTEN/NOTIFY mechanism offered by Postgres. Basically you will just need to define which callback(s) should be called on a specific notification and that's it

## Usage

Add Boltun as a dependency in your `mix.exs` file.

```elixir
defp deps do
  [{:boltun, "~> 1.0.2"}]
end
```

After you are done, run `mix deps.get` in your shell to fetch the dependencies.

## Defining a listener

Defining a listener is trivial. See the example below

```elixir
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
```

The channel is a concept defined by Postgres. On the SQL side you will have something like `NOTIFY my_channel, 'my payload'` happening, for example, in a trigger which will cause your callbacks TestListener.my_callback and TestListener.my_other_callback to be called. The callbacks will be invoked synchronously in the order they were declared in the listen block.

## Using a listener

Defining a listener is not enough to use it. It should be started with `TestListener.start_link`. You can do this, for example, in a supervisor.
The listener also needs the connection parameters to establish a connection. You will provide this in your config.exs file in this format

```elixir
  ...
  config :my_app, TestListener, database: "postgres", username: "postgres", password: "postgres", hostname: "localhost"
  ...
```

The full list of options can be read in the documentation for Postgrex.

## License
Copyright (c) 2014, Bitgamma OÜ <michele@briksoftware.com>

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
