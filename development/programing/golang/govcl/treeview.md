# treeview

直接上代码

## 代码

```go
f.TreeView1.SetImages(f.ImageList1)

node := f.TreeView1.Items().AddFirst(nil, "根节点")
node.SetImageIndex(0)
node = f.TreeView1.Items().AddChild(node, "222");
f.TreeView1.Items().AddChild(node, "333");
```
