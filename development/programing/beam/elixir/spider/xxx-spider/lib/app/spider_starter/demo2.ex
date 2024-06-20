defmodule Demo2.SpiderStarter do
  def start() do
    Demo2.ArticleListSup.start_child(
      %{
        "main_type_name" => "江苏",
        "sub1_type_name" => "江苏省科技厅",
        "sub2_type_name" => "科技资讯",
        "sub3_type_name" => "通知公告"
      },
      "http://kxjst.jiangsu.gov.cn/module/web/jpage/dataproxy.jsp?startrecord=1&endrecord=45&perpage=15",
      # 表单参数
      %{
        "col" => "1",
        "appid" => "1",
        "webid" => "89",
        "path" => "/",
        "columnid" => "82540",
        "sourceContentType" => "1",
        "unitid" => "345950",
        "webname" => "江苏省科技厅",
        "permissiontype" => "0"
      },
      # header的额外参数
      %{
        "Referer" => "http://kxjst.jiangsu.gov.cn/col/col82540/index.html",
        "Content-Type" => "application/x-www-form-urlencoded; charset=UTF-8",
        "Host" => "kxjst.jiangsu.gov.cn"
      }
    )
  end
end
