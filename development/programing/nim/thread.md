# thread

## 例子

```nim
import locks

var
  threadList: array[0..4, Thread[tuple[a,b: int]]]
  locker: Lock

# {.thread.} 是编译指示
proc threadProc(item: tuple[a,b: int]) {.thread.} =
  for i in item.a..item.b:
    acquire(locker)
    echo("线程id ", int(i/10), " i ", i)
    release(locker)

initLock(locker)
for i in 0..high(threadList):
  createThread(threadList[i], threadProc, (i*10, i*10+5))
joinThreads(threadList)
```
