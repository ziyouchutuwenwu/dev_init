import Config

config :logger,
  level: :warning

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

config :spider, CrontabScheduler,
  debug_logging: false,
  timezone: "Asia/Shanghai",
  jobs: [
    {"43 08 * * *", {CronTask, :on_cron, []}}
  ]

config :spider, Sleeper,
  min_duration: 5 * 60,
  max_duration: 20 * 60

config :spider,
  data_save_base_dir: "/data",
  tika_url: "http://xxx-spider-tika:9998/tika",
  splash_url: "http://xxx-spider-splash:8050",
  redis_host: "xxx-redis",
  redis_port: 6379,
  redis_passwd: "",
  redis_db: 0
