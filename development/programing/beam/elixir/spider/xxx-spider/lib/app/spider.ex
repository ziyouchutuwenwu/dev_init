defmodule Spider do
  require Logger
  use Task

  def start_link() do
    Task.start_link(__MODULE__, :run, [])
  end

  def run() do
    case ConfigFetcher.get_running_mode() do
      :prod ->
        Logger.info("prod 模式，准备启动爬虫")
        start_prod_spiders()

      :dev ->
        Logger.debug("dev 模式")

      _ ->
        Logger.info("其它模式")
    end
  end

  def start_prod_spiders() do
    Demo1.SpiderStarter.start()
    Demo2.SpiderStarter.start()
  end

  def start_debug_spider() do
  end
end
