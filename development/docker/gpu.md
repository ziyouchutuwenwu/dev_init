# gpu

## 说明

容器通过 container-toolkit, 直接调用主机上的 nvidia-xxx 相关的工具

## 步骤

### 物理机

安装显卡驱动

安装 nvidia-container-toolkit

### 容器

```sh
docker run --rm --gpus all debian:stable nvidia-smi
```
