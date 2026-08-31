# venv

## 用法

### 创建

```sh
# 默认位置 .venv
uv venv
```

指定目录

```sh
uv venv dev_env --python 3.12
```

### 依赖

```sh
uv pip install xxx
```

```sh
# 导出到 requirements.txt
uv pip freeze > requirements.txt
```

同步依赖

```sh
uv pip sync ./requirements.txt
```
