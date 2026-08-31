# x-anylabeling

## 说明

[官网](https://github.com/CVHub520/X-AnyLabeling/releases)

[远程推理](https://github.com/CVHub520/X-AnyLabeling-Server)

## 用法

xanylabeling

```sh
uv venv anylabel --python 3.12
uv pip install "x-anylabeling-cvhub[cpu]"
```

远程推理

```sh
git clone https://github.com/CVHub520/X-AnyLabeling-Server.git
uv pip install -e '.[all]'
uv run x-anylabeling-server
```
