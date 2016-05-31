defmodule ConnHelper do
  def start_connection do
    elem(Postgrex.start_link(Application.get_env(:boltun, Boltun.TestListener)), 1)
  end

  def notify(channel, payload) do
    conn = start_connection
    Postgrex.query(conn, "NOTIFY #{channel}, '#{payload}'", [])
  end
end
