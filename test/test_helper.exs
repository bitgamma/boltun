Application.put_env(:boltun, Boltun.TestListener, [database: "postgres", username: "postgres", password: "postgres", hostname: "localhost"])
ExUnit.start()
