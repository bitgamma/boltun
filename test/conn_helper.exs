defmodule ConnHelper do
  def start_connection do
    elem(Postgrex.Connection.start_link(Application.get_env(:boltun, Boltun.TestListener)), 1)
  end

  def notify(channel, payload) do
    conn = start_connection
    Postgrex.Connection.query(conn, "NOTIFY #{channel}, '#{payload}'", [])
    Postgrex.Connection.stop(conn)
  end
end