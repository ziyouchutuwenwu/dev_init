defmodule Debug do
  def restart() do
    Supervisor.terminate_child(AppSup, MainSup)
    Supervisor.restart_child(AppSup, MainSup)
  end

  def check_list() do
    Supervisor.which_children(ArticleListSup)
  end

  def check_article() do
    Supervisor.which_children(ArticleSup)
  end
end
