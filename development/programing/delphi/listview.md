# listview

由于 delphi 出来的早，很多设计相对来说还是比较反人类，仅以此记录备忘

## 基础设置

- 设置 ViewStyle 为 vsReport
- 控件右键，column editor, 添加以后，在左边的面板里面，针对 colume 修改 title,width 等等

## 添加数据

### 静态

右键，new item,只能添加最左边的数据，其他的，需要 new sub item

### 动态添加

```pascal
items := self.ListView1.Items.Add();
items.Caption := 'abc';
items.SubItems.Add('mmm');
items.SubItems.Add('xyz');
```

### 设置小图标

```pascal
self.ListView1.SmallImages := self.ImageList1;
items := self.ListView1.Items.Add();
items.ImageIndex := 0;
```
