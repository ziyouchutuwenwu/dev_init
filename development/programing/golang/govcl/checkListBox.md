# checkListBox

## 直接上代码

```go
f.CheckListBox1.Items().Add("aaa")
f.CheckListBox1.Items().Add("bbb")

f.CheckListBox1.SetItemEnabled(0, false)
f.CheckListBox1.SetChecked(1, true)

f.CheckListBox1.SetOnClickCheck(func(sender vcl.IObject) {
    fmt.Println("check单击")
})
```
