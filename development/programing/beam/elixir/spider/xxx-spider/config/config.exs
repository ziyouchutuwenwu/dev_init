import Config

config :spider, mode: config_env()
import_config "#{config_env()}.exs"
