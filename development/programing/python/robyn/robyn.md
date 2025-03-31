# robyn

## 说明

基于 rust 的极高性能 web 框架

## 例子

ctllers.py

```python
# 异步
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


app = Robyn(__file__)
routes.make(app)

if __name__ == "__main__":
    app.start(host="0.0.0.0", port=8080)
```
