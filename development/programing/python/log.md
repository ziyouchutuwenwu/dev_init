# log

## 说明

自带的 log 库太难用，用 loguru 代替

## 用法

### 基础

```python
from loguru import logger
logger.debug("xxx {}", 123)
```

### 特殊

log.py

```python
from loguru import logger
import sys

# 需要特殊处理 log
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
import log
log.init()
```

然后和基础用法一样用
