# gpu

## 说明

容器里面的 nvidia 相关不需要装，是在主机上装

## 步骤

### 宿主机

安装驱动

docker 安装 nvidia-container-runtime

### 容器

```sh
docker run -d -it --gpus all --name deb debian:stable bash
```
