# rknn

## 说明

- [mpp](https://github.com/rockchip-linux/mpp/)
- [zoo](https://github.com/airockchip/rknn_model_zoo/)

## 结构

```sh
├── 3rdparty
│   ├── model_license
│   │   ├── include
│   │   │   └── model_license.h
│   │   └── lib
│   │       └── libmodel_license.a
│   ├── mpp
│   │   └── inc
│   └── rknn_model_zoo
│       ├── 3rdparty
│       │   ├── librga
│       │   ├── rknpu2
│       │   └── stb_image
│       └── utils
├── include
└── src
```

## 依赖复制

### mpp

```sh
mpp/inc

复制到

3rdparty/mpp/inc
```

### rknn_model_zoo

硬件加速与图像处理依赖

```sh
rknn_model_zoo/3rdparty/ 下的 librga、rknpu2、stb_image

复制到

3rdparty/rknn_model_zoo/3rdparty/
```

模型后处理与工具源码

```sh
rknn_model_zoo/utils

复制到

3rdparty/rknn_model_zoo/
```

### 加密库

由 encrypter 提供，保存到 3rdparty/model_license
