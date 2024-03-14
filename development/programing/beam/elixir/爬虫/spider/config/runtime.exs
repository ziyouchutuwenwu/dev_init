import Config

# if config_env() === :prod do
#   config :spider,
#     data_save_base_dir: System.get_env("DATA_SAVE_BASE_DIR"),
#     splash_url: System.get_env("SPLASH_URL"),
#     redis_host: System.get_env("REDIS_HOST")
# end

if config_env() === :prod do
  if System.get_env("DATA_SAVE_BASE_DIR") do
    config :spider,
      data_save_base_dir: System.get_env("DATA_SAVE_BASE_DIR")
  end

  if System.get_env("SPLASH_URL") do
    config :spider,
      splash_url: System.get_env("SPLASH_URL")
  end

  if System.get_env("TIKA_URL") do
    config :spider,
      tika_url: System.get_env("TIKA_URL")
  end

  if System.get_env("REDIS_HOST") do
    config :spider,
      redis_host: System.get_env("REDIS_HOST")
  end
end
