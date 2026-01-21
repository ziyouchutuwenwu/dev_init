# loguru

## 说明

自带的 log 库太难用

## 用法

log.py

```python
from loguru import logger
import sys

def init():
    logger.remove()
    logger.add(
        sys.stdout,
        level="DEBUG",
        format="[<green>{time:HH:mm:ss}</green>] [<level>{level}</level>] {message}"
    )
```

main.py

```python
# 先 init
import log
log.init()

from loguru import logger
logger.debug("xxx {}", 123)
```
