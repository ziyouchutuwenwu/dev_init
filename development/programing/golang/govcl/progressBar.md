# progressBar

## 例子

```go
var max int32 = 10000

f.ProgressBar1.SetMin(1)
f.ProgressBar1.SetMax(max)
f.ProgressBar1.SetStep(int32(1))
f.ProgressBar1.SetEnabled(true)

go func() {
  for i := 1; int32(i) <= max; i++{
      time.Sleep(time.Millisecond)
      vcl.ThreadSync(func() {
          f.ProgressBar1.SetPosition(int32(i));
      })
  }
}()
```
