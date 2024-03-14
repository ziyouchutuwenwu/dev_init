defmodule Sleeper do
  require Logger

  def random_deplay() do
    [min_duration: min, max_duration: max] = ConfigFetcher.get_sleeper()
    timeout = Enum.random(Enum.to_list(min..max))
    Logger.info("延迟 #{timeout}s")
    Process.sleep(timeout * 1000)
  end
end
