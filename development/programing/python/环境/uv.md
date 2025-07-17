# uv

## 说明

uv 为项目创建隔离的虚拟环境

uvx 用于在临时环境中运行

## 安装

[手动下载](https://github.com/astral-sh/uv)

## 项目内

### 创建

```sh
uv init demo
```

### venv

```sh
uv venv

# 指定版本
uv venv --python 3.10
```

### 依赖

增加依赖

```sh
# 这个 pip 是 uv 模拟的
uv pip install requests

# 这个会更新 pyproject.toml，推荐
uv add requests
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

## 全局

### pip

```sh
uv pip install --system -U xxx
```

### uvx

在临时目录中下载，全局运行

```sh
uvx xxx
```
