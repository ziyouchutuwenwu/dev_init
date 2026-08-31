# xanylabeling

## 说明

[官网](https://github.com/CVHub520/X-AnyLabeling)

[远程推理](https://github.com/CVHub520/X-AnyLabeling-Server)

## 用法

xanylabeling

```sh
uv venv anylabel --python 3.12
uv pip install "x-anylabeling-cvhub[cpu]"

# crtl-a, 选择模型
uv run xanylabeling
```

本地无 gpu, 远程才有

```sh
git clone https://github.com/CVHub520/X-AnyLabeling-Server.git
uv evnv
uv pip install -e '.[all]'

uv run x-anylabeling-server \
  --config configs/server.yaml \
  --models-config configs/models.yaml
```
