defmodule CronTask do
  require Logger

  def on_cron do
    Logger.warning("触发定时任务")
    Supervisor.terminate_child(AppSup, MainSup)
    Supervisor.restart_child(AppSup, MainSup)
  end
end
