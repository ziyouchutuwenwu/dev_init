# pytorch

## 说明

需要先装显卡驱动和 cuda

## 步骤

[文档](https://pytorch.org/get-started/locally/)

```sh
uv add torch torchvision --index https://download.pytorch.org/whl/cu124
```

验证

```sh
uv run python -c "
import torch

print(torch.__version__)
print(torch.version.cuda)
print(torch.cuda.is_available())
"
```
