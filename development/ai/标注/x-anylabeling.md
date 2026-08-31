# x-anylabeling

## 说明

[官网](https://github.com/CVHub520/X-AnyLabeling)

[远程推理](https://github.com/CVHub520/X-AnyLabeling-Server)

## 用法

xanylabeling

```sh
uv venv anylabel --python 3.12
uv pip install "x-anylabeling-cvhub[cpu]"
uv run xanylabeling
```

x-anylabeling-server

```sh
uv venv label_server --python 3.12

git clone https://github.com/CVHub520/X-AnyLabeling-Server.git
uv pip install -e '.[all]'
```
