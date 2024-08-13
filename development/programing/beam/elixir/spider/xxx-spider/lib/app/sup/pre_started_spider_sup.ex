defmodule PreStartedSpiderSup do
  require Logger
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    Logger.info("正在启动所有爬虫的 supervisor")

    demo1 = PreStartedSpiderSups.Demo1.SpiderSupInfo.get_sup_list()
    demo2 = PreStartedSpiderSups.Demo2.SpiderSupInfo.get_sup_list()

    children = demo1 ++ demo2

    Supervisor.init(children, strategy: :one_for_one)
  end
end
