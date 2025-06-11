# uv

## 说明

项目级虚拟环境，推荐

## 用法

创建

```sh
uv init demo
```

激活 venv, 没有就会自动创建

```sh
# 一定要 uv xxx
uv venv

uv pip install requests
uv add requests
```

基于当前 venv 运行

```sh
uv run xxx
uv run python main.py
```
