# treeview

## 动态添加节点

```pascal
var
  node: TTreeNode;
begin
  node := self.TreeView1.Items.AddFirst(nil,'demo_node');
  node := self.Treeview1.Items.AddChildObject(node, '222', nil);
  self.Treeview1.Items.AddChildObject(node, '333', nil);
end;
```
