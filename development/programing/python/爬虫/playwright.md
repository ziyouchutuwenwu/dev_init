# playwright

## 说明

自动化测试和爬虫工具，因为是调用浏览器，所以基本上可以通杀 js

## 配置

mirror

```sh
export PLAYWRIGHT_DOWNLOAD_HOST="https://npmmirror.com/mirrors/playwright"
```

```sh
# 完整版
playwright install chromium

# 无头版，更快更小
playwright install chromium-headless-shell
```
