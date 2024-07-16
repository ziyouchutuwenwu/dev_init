defmodule Spider.Application do
  use Application

  def start(_type, _args) do
    children = [
      # 定时任务
      CrontabScheduler,
      %{
        id: MainSup,
        start: {MainSup, :start_link, []},
      }
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: AppSup)
  end
end
