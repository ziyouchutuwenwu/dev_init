import Config

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

config :spider, mode: config_env()
import_config "#{config_env()}.exs"
