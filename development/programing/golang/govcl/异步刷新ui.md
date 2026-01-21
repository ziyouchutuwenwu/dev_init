# 异步刷新 ui

## 代码

```go
go func() {
    vcl.ThreadSync(func() {
        vcl.ShowMessage("这是主线程的异步对话框")
    })
}()
```
