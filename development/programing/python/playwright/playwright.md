# playwright

## 说明

自动化测试和爬虫工具，因为是调用浏览器，所以基本上可以通杀 js

## 安装

```sh
pip install playwright
```

```sh
# 开发用
playwright install chromium

# 生产用，修改代码的 headless 为 true 即可
playwright install chromium-headless-shell

# 查看可用的浏览器
playwright install --help
```

## 录制脚本

生成代码，非常方便

```sh
playwright codegen https://www.google.com --proxy-server=socks5://127.0.0.1:1080
```
