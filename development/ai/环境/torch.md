# torch

## 说明

检测并安装最高的兼容的 torch

## 用法

只支持 `uv pip install`

不支持 `uv add`

```sh
# 自动探测
export UV_TORCH_BACKEND=auto
# 指定版本
export UV_TORCH_BACKEND=cu126
```

实际上就是下面的缩写

```sh
UV_EXTRA_INDEX_URL="https://download.pytorch.org/whl/cu126"
```
