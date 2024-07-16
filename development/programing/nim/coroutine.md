# coroutine

## 说明

需要特殊的编译参数

```sh
-d:nimCoroutines
-d:nimCoroutinesUcontext
-d:nimCoroutinesSetjmp
-d:nimCoroutinesSetjmpBundled
```

## 例子

```nim
import coro

proc proc1() =
  for i in 0..10:
    echo(i, "in proc1")
    suspend()

proc proc2() =
  for i in 0..10:
    echo(i, "in proc2")
    suspend()

let coroutine1 = start(proc1)
let coroutine2 = start(proc2)

while alive(coroutine1) or alive(coroutine2):
  coro.run()
```
