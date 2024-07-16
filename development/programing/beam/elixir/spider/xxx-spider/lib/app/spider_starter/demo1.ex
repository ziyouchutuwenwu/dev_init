defmodule Demo1.SpiderStarter do
  def start() do
    Demo1.ArticleListSup.start_child(
      %{
        "main_type_name" => "煤化工信息网",
        "sub1_type_name" => "政策法规"
      },
      "http://www.meihuake.net/info-1-c.html"
    )

    Demo1.ArticleListSup.start_child(
      %{
        "main_type_name" => "煤化工信息网",
        "sub1_type_name" => "行业资讯"
      },
      "http://www.meihuake.net/info-2-c.html"
    )
  end
end
