# wrk

支持 lua 脚本, 命令大概类似

## lua 例子

```lua
wrk.method = "POST"
wrk.headers["Content-Type"] = "application/x-www-form-urlencoded"
wrk.body = "foo=bar&baz=quux"

-- 启动阶段 （每个线程执行一次）
-- function setup(thread)
--    print("----------启动阶段----------------")
--    print("setup",thread)
--    print("setup",thread.addr)
-- end


-- -- 运行阶段 （该方法init每个线程执行一次）
-- function init(args)
--    print("-----------运行阶段---------------")
--    print("init",args)
-- end


-- 这个三个方法每个请求都会调用一次
function delay()
 print("delay")
 -- 设置延迟 990 ms
 return 990
end

-- function request()
--   print("request")
--   print(wrk.body)
--   print(wrk.headers["Content-Type"])
--   print(wrk.method)
--   -- 这个方法必须要有返回，不然会出错
--   return wrk.request()
-- end

function response(status, headers, body)
  if status ~= 200 then
    io.write("status ".. status .."\n")
    io.write("response:\n")
    io.write(body .. "\n")
    io.write("\n")
  end
end

-- -- 结束阶段
-- function done(summary, latency, requests)
--    print("-----------结束阶段---------------")
--   print("done",summary,latency,requests)
-- end
```

## 用法

```sh
wrk --threads 1 --connections 8 --duration 20s --script=./demo.lua --latency http://192.168.xxxx/xxxx
```

### 线程数

参数 --threads, 一般是物理 cpu 核数

### 连接数

参数 --connections 可以理解为并发数，一般在测试过程中，这个值需要使用者不断向上调试，直至 qps 达到一个临界点，便可认为此时的并发数为系统所能承受的最大并发量。

实际上，wrk 会为每个线程分配（connections/threads）个 socket 连接，每个连接会先执行请求动作，然后等待直到收到响应后才会再发送请求，这个日后会有关于 wrk 的源码解析方便理解，所以每个时间点的并发数大致等于连接数（connection）

#### 公式

`qps = 1000/time * connections`

时间为 1ms，如果 connections（连接数）为 1，则理论上 qps 接近 1000，如果 connections（连接数）为 100，则 QPS 接近 10w
时间为 10ms，如果 connections（连接数）为 1，则理论上 qps 接近 100，如果 connections（连接数）为 100，则 QPS 接近 1w

## 注意

### Socket 错误

调节系统的文件打开限制数

### None 2xx 失败数

```sh
请求参数错误，服务器未过滤
被测试的服务顶不住持续请求
线程数设置可能需要调整
```
