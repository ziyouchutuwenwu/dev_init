import Config

config :logger,
  level: :debug

config :spider,
  httpoison_option: [
    hackney: [
      use_default_pool: false,
      insecure: true
    ],
    timeout: :infinity,
    checkout_timeout: :infinity,
    recv_timeout: :infinity
  ]

config :spider, Sleeper,
  min_duration: 10,
  max_duration: 60

config :spider,
  data_save_base_dir: System.get_env("HOME") |> Path.join("downloads/数据采集test"),
  tika_url: "http://127.0.0.1:9998/tika",
  splash_url: "http://127.0.0.1:8050",
  redis_host: "127.0.0.1",
  redis_port: 6379,
  redis_passwd: "",
  redis_db: 0
