defmodule PreStartedSpiderSups.Demo1.SpiderSupInfo do
  alias Demo1.{ArticleListSup, ArticleSup}

  def get_sup_list do
    [
      %{
        id: ArticleListSup,
        start: {ArticleListSup, :start_link, []},
        type: :supervisor
      },
      %{
        id: ArticleSup,
        start: {ArticleSup, :start_link, []},
        type: :supervisor
      }
    ]
  end
end
