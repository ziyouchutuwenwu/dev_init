# log

## 用法

log.py

```python
import logging
import sys


def setup(level=logging.DEBUG):
    for handler in logging.root.handlers[:]:
        logging.root.removeHandler(handler)

    logging.basicConfig(
        level=level,
        format="%(message)s",
        # format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        # datefmt="%Y-%m-%d %H:%M:%S",
        handlers=[
            logging.StreamHandler(sys.stdout),
        ],
    )

    # 设置第三方库的日志级别（避免噪音）
    logging.getLogger("urllib3").setLevel(logging.WARNING)
    logging.getLogger("requests").setLevel(logging.WARNING)


def get_logger(name):
    return logging.getLogger(name)
```

main.py

```python
import logging
import log

log.setup(level=logging.INFO)
logger = log.get_logger(__name__)


def main():
    logger.debug("这是 debug")
    logger.info("这是 info")
    logger.warning("这是 warning")
    logger.error("这是 error")


if __name__ == "__main__":
    main()
```
