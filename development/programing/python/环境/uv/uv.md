# uv

## 说明

项目级虚拟环境，推荐

## 用法

创建

```sh
uv init demo
```

venv

```sh
uv venv
uv venv --python 3.12.0
```

```sh
uv pip install requests
uv add requests
```

基于当前 venv 运行

```sh
uv run xxx
uv run python main.py
```

依赖

```sh
uv sync
uv pip sync ./requirements.txt
```
