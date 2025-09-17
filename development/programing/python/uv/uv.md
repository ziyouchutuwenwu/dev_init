# uv

## 说明

uv 为项目创建隔离的虚拟环境

uvx 用于在临时环境中运行

## 用法

### 创建项目

```sh
uv init demo
```

### 环境隔离

```sh
uv venv

# 指定版本
uv venv --python 3.10
```

### 依赖相关

增加依赖

```sh
# 这个会更新 pyproject.toml，推荐
uv add requests

# 这个 pip 是 uv 模拟的
uv pip install requests
```

生成依赖文件

```sh
uv pip freeze > requirements.txt
uv pip compile pyproject.toml -o requirements.txt
```

同步依赖

```sh
uv sync

uv pip sync ./pyproject.toml
uv pip sync ./requirements.txt
```

### 运行

基于当前 venv 运行

```sh
uv run xxx
uv run main.py
```

## 全局工具

安装到 `$HOME/.local/bin`

```sh
uv tool install -U xxx
```

一次性运行工具，不需要提前安装，也不污染全局环境

```sh
uvx xxx
```
