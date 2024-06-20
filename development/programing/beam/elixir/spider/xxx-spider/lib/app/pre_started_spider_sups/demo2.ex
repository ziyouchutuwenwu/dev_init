defmodule PreStartedSpiderSups.Demo2.SpiderSupInfo do
  alias Demo2.{ArticleListSup, ArticleHtmlSup, ArticleBinSup, ArticleTikaSup}

  def get_sup_list do
    [
      %{
        id: ArticleListSup,
        start: {ArticleListSup, :start_link, []},
        type: :supervisor
      },
      %{
        id: ArticleHtmlSup,
        start: {ArticleHtmlSup, :start_link, []},
        type: :supervisor
      },
       %{
        id: ArticleBinSup,
        start: {ArticleBinSup, :start_link, []},
        type: :supervisor
      },
       %{
        id: ArticleTikaSup,
        start: {ArticleTikaSup, :start_link, []},
        type: :supervisor
      }
    ]
  end
end
