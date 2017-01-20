defmodule Boltun.ListenerTest do
  use ExUnit.Case
  import ConnHelper

  test "add callbacks" do
    Process.register(self(), BoltunTest)
    {:ok, sup} = Boltun.Supervisor.start_link([connection: Application.get_env(:boltun, Boltun.TestListener), name: Boltun.TestListener])

    Boltun.Listener.add_callback(Boltun.TestListener.Listener, "test_channel", {Boltun.TestListener, :test, []})
    notify("test_channel", "test")

    assert_receive({:test_test_channel, "test"}, 1000)

    Process.unregister(BoltunTest)
    Process.exit(sup, :normal)
  end

  test "add multiple callbacks" do
    Process.register(self(), BoltunTest)
    {:ok, sup} = Boltun.Supervisor.start_link([connection: Application.get_env(:boltun, Boltun.TestListener), name: Boltun.TestListener])

    Boltun.Listener.add_callback(Boltun.TestListener.Listener, "test_channel", {Boltun.TestListener, :test, []})
    Boltun.Listener.add_callback(Boltun.TestListener.Listener, "test_channel", {Boltun.TestListener, :other_test, []})

    Boltun.Listener.add_callback(Boltun.TestListener.Listener, "other_channel", {Boltun.TestListener, :test, []})
    Boltun.Listener.add_callback(Boltun.TestListener.Listener, "other_channel", {Boltun.TestListener, :other_test, []})

    notify("test_channel", "test")

    assert_receive({:test_test_channel, "test"}, 1000)
    assert_receive({:other_test_channel, "test"}, 1000)

    notify("other_channel", "test")

    assert_receive({:test_other_channel, "test"}, 1000)
    assert_receive({:other_other_channel, "test"}, 1000)

    Process.unregister(BoltunTest)
    Process.exit(sup, :normal)
  end

  test "remove callbacks" do
    Process.register(self(), BoltunTest)
    {:ok, sup} = Boltun.Supervisor.start_link([connection: Application.get_env(:boltun, Boltun.TestListener), name: Boltun.TestListener])

    Boltun.Listener.add_callback(Boltun.TestListener.Listener, "test_channel", {Boltun.TestListener, :test, []})
    Boltun.Listener.add_callback(Boltun.TestListener.Listener, "other_channel", {Boltun.TestListener, :test, []})
    Boltun.Listener.add_callback(Boltun.TestListener.Listener, "other_channel", {Boltun.TestListener, :other_test, []})
    Boltun.Listener.remove_channel(Boltun.TestListener.Listener, "other_channel")

    notify("other_channel", "test")
    refute_receive({:test_other_channel, "test"}, 1000)

    notify("test_channel", "test")
    assert_receive({:test_test_channel, "test"}, 1000)

    Process.unregister(BoltunTest)
    Process.exit(sup, :normal)
  end
end
