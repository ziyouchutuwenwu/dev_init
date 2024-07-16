# zeromq

## 例子

一般用于多语言间通信

### java 服务端

pom.xml

```xml
<dependency>
  <groupId>org.zeromq</groupId>
  <artifactId>jeromq</artifactId>
  <version>0.5.3</version>
</dependency>
```

```java
package org.example;

import org.zeromq.SocketType;
import org.zeromq.ZMQ;
import org.zeromq.ZContext;

public class App
{
    public static void main( String[] args )
    {
        try (ZContext context = new ZContext()) {
            ZMQ.Socket socket = context.createSocket(SocketType.REP);
            socket.bind("tcp://*:5555");

            while (!Thread.currentThread().isInterrupted()) {
                byte[] reply = socket.recv(0);
                System.out.println("got: " + new String(reply, ZMQ.CHARSET));

                String response = "java";
                socket.send(response.getBytes(ZMQ.CHARSET), 0);
            }
        }
    }
}
```

### golang 客户端

```golang
package main

import (
  "context"
  "fmt"
  zmq "github.com/go-zeromq/zmq4"
  "github.com/gogf/gf/v2/encoding/gjson"
  "time"
)

var socket zmq.Socket = nil

func main() {
  connect("192.168.0.109:5555")
  check()
  disconnect()
}

func connect(server string) bool {
  ctx := context.Background()
  socket = zmq.NewReq(ctx, zmq.WithDialerRetry(time.Second))
  serverUrl := fmt.Sprintf("tcp://%s", server)
  if err := socket.Dial(serverUrl); err != nil {
    return false
  }

  return true
}

func check() (bool, string) {
  msg := zmq.NewMsgString("")
  _ = socket.Send(msg)

  response, err := socket.Recv()
  if err != nil {
    return false, "通信失败"
  }
  info := string(response.Bytes())
  responseJson := gjson.New(info)

  if responseJson.Get("status").Int() != 200 {
    return false, responseJson.Get("message").String()
  }
  return true, ""
}

func disconnect() {
  _ = socket.Close()
}
```

### python 客户端

```sh
pip install zmq
```

```python
import zmq

context = zmq.Context()

socket = context.socket(zmq.REQ)
socket.connect("tcp://localhost:5555")

for request in range(10):
    data = bytes("python", 'utf-8')
    socket.send(data)

    message = socket.recv()
    print("got", message.decode("utf-8"))
```
