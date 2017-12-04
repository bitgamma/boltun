defmodule Boltun.ConfigTestListener do
  use Boltun, config: fn ->
    [database: "postgres", username: "postgres", password: "postgres", hostname: "localhost"]
  end

  listen do
    channel "test_channel", :test
  end

  def test("test_channel", id) do
    send BoltunTest, {:test_test_channel, id}
  end
end

defmodule Boltun.TestListener do
  use Boltun, otp_app: :boltun

  listen do
    channel "test_channel", :test
  end

  def test("test_channel", id) do
    send BoltunTest, {:test_test_channel, id}
  end

  def test("other_channel", id) do
    send BoltunTest, {:test_other_channel, id}
  end

  def other_test("test_channel", id) do
    send BoltunTest, {:other_test_channel, id}
  end

  def other_test("other_channel", id) do
    send BoltunTest, {:other_other_channel, id}
  end
end

defmodule BoltunTest do
  use ExUnit.Case
  import ConnHelper

  test "configs from function" do
    Process.register(self(), BoltunTest)
    Boltun.ConfigTestListener.start_link

    notify("test_channel", "test")

    assert_receive({:test_test_channel, "test"}, 1000)

    Process.unregister(BoltunTest)
  end

  test "listens to notifications" do
    Process.register(self(), BoltunTest)
    Boltun.TestListener.start_link

    notify("test_channel", "test")

    assert_receive({:test_test_channel, "test"}, 1000)

    Process.unregister(BoltunTest)
  end
end
