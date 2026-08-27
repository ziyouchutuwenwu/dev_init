# gpu

## 说明

容器通过 container-toolkit, 直接调用主机上的 nvidia-xxx 相关的工具

## 步骤

### 宿主机

安装显卡驱动

docker 安装 nvidia-container-toolkit

### 容器

```sh
docker run -d -it --gpus all --name deb debian:stable bash
```
