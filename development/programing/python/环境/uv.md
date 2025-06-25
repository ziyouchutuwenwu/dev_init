# uv

## 说明

虚拟环境

## 安装

[手动下载](https://github.com/astral-sh/uv)

## 用法

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

### 版本错误

创建 uv 项目的时候，指定的版本和系统 python 版本不一致，uv 会自己下载指定的版本并且缓存

```sh
uvx python --version
```

删除缓存目录即可

```sh
rm -rf $HOME/.local/share/uv/
```
