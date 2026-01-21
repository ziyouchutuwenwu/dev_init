# listview

直接上代码

## 代码

```go
f.ListView1.SetViewStyle(types.VsReport)
column := f.ListView1.Columns().Add()
column.SetWidth(100)
column.SetCaption("测试1")

column = f.ListView1.Columns().Add()
column.SetWidth(100)
column.SetCaption("测试2")

column = f.ListView1.Columns().Add()
column.SetWidth(100)
column.SetCaption("测试3")

f.ListView1.SetSmallImages(f.ImageList1)
items := f.ListView1.Items().Add()
items.SetImageIndex(0)
items.SetCaption("数据")
items.SubItems().Add("aaa")
items.SubItems().Add("bbb")
```
