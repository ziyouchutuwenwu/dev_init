defmodule ConfigFetcher do
  def get_httpoison_config() do
    Application.get_env(:spider, :httpoison_option)
  end

  def get_running_mode() do
    Application.get_env(:spider, :mode)
  end

  def get_tika_url() do
    Application.get_env(:spider, :tika_url)
  end

  def get_sleeper() do
    Application.get_env(:spider, Sleeper)
  end

  def get_data_save_base_dir() do
    Application.get_env(:spider, :data_save_base_dir)
  end

  def get_splash_url() do
    Application.get_env(:spider, :splash_url)
  end

  def get_redis_host() do
    Application.get_env(:spider, :redis_host)
  end

  def get_redis_port() do
    Application.get_env(:spider, :redis_port)
  end

  def get_redis_passwd() do
    Application.get_env(:spider, :redis_passwd)
  end

  def get_redis_db() do
    Application.get_env(:spider, :redis_db)
  end
end
