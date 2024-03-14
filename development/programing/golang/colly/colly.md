# colly

## 说明

- 不能自定义回调函数

- 一个页面配一个 collector, 准确的说，是一个 url 配一个 collector，或者在 callback 里面想办法区分

- 自定义参数通过 ctx 传递

## 代码

```go
package main

import (
  "fmt"
  "github.com/antchfx/htmlquery"
  "github.com/gocolly/colly/v2"
  "log"
  "strings"
)

func main() {
  collector := colly.NewCollector(
    //colly.AllowedDomains("wxlx.gov.cn"),
    colly.URLFilters(regexp.MustCompile(".*.wxlx.gov.cn.*")),
  )

  collector.OnRequest(func(r *colly.Request) {
    fmt.Println("访问", r.URL.String())
    r.Ctx.Put("aa", "bb")
  })

  collector.OnResponse(func(r *colly.Response) {
    doc, _ := htmlquery.Parse(strings.NewReader(string(r.Body)))
    nodes := htmlquery.Find(doc, `//div[@id="zoom"]//p//text()`)
    for _, node := range nodes {
      log.Println(node.Data, r.Ctx.Get("aa"))
    }
  })

  collector.OnError(func(reponse *colly.Response, err error) {
    log.Println("err", err.Error())
  })

  collector.OnScraped(func(r *colly.Response) {
    log.Println("爬取结束", r.Ctx.Get("aa"))
  })

  collector.Visit("https://www.wxlx.gov.cn/xxgk/index.shtml")
}
```
