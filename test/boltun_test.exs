defmodule Boltun.TestListener do
  use Boltun, otp_app: :boltun

  listen do
    channel "test_channel", :test
  end

  def test("test_channel", id) do
    send BoltunTest, {:test_channel, id}
  end   
end

defmodule BoltunTest do
  use ExUnit.Case

  defp connection do
    elem(Postgrex.Connection.start_link(Application.get_env(:boltun, Boltun.TestListener)), 1)
  end

  test "listens to notifications" do
    Process.register(self, BoltunTest)
    Boltun.TestListener.start_link
    Postgrex.Connection.query(connection, "NOTIFY test_channel, 'test'", [])

    assert_receive({:test_channel, "test"}, 1000)

    Process.unregister(BoltunTest)
  end
end
