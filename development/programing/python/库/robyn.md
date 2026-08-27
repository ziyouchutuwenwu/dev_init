# robyn

## 说明

基于 rust 的极高性能 web 框架

## 例子

ctllers.py

```python
# 加 async 以后，直接支持 asyncio
async def demo(request):
    return "aaaaaaaaaaaa"
```

routes.py

```python
from robyn import Robyn
import ctllers


# GTE, POST 等一定要大写
def make(app: Robyn):
    app.add_route("GET", "/", ctllers.demo)
```

main.py

```python
from robyn import Robyn
import routes
import socket
import sys
import signal


def check_port(host, port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        try:
            s.bind((host, port))
            return True
        except OSError:
            return False


def signal_handler(sig, frame):
    print("shutting down gracefully...")
    sys.exit(0)


if __name__ == "__main__":
    host = "0.0.0.0"
    port = 8080

    if not check_port(host, port):
        print(f"error: 端口 {port} 被占用")
        sys.exit(1)

    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    app = Robyn(__file__)
    routes.make(app)
    app.start(host=host, port=port)
```
