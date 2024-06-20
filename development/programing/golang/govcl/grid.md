# grid

具体例子见 `govcl/samples/grids/stringgrid2`

## 测试代码如下

```go
func (f *TForm1) OnFormCreate(sender vcl.IObject) {

    f.StringGrid1.SetAlign(types.AlClient)
    f.StringGrid1.SetFixedCols(0)
    f.StringGrid1.SetOptions(f.StringGrid1.Options().Include(types.GoAlwaysShowEditor, types.GoCellHints, types.GoEditing, types.GoTabs))

    column := f.StringGrid1.Columns().Add()

    column = f.StringGrid1.Columns().Add()
    column.SetButtonStyle(types.CbsButtonColumn)
    column.SetWidth(100)
    column.Title().SetCaption("测试按钮")
    f.StringGrid1.SetOnButtonClick(f.onGridButtonClick)


    column = f.StringGrid1.Columns().Add()
    column.SetButtonStyle(types.CbsPickList)
    column.SetWidth(150)
    column.Title().SetCaption("下拉列表")
    column.PickList().Add("Cow")
    column.PickList().Add("Dog")
    column.PickList().Add("Pig")
    column.PickList().Add("Goat")
    column.PickList().Add("Elephant")
}

func (f *TForm1) onGridButtonClick(sender vcl.IObject, column, row int32) {
    vcl.ShowMessage("哀伤的")
}
```
