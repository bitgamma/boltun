Code.require_file("conn_helper.exs", __DIR__)

Application.put_env(:boltun, Boltun.TestListener, [database: "postgres", username: "postgres", password: "postgres", hostname: "localhost"])
ExUnit.start()
