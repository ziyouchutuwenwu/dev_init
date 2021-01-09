# yolov5

## 源码

```sh
git clone https://github.com/ultralytics/yolov5
cd yolov5
pip install -r requirements.txt
```

windows 下

```sh
需要打开 pytorch.org，参考官方资料安装 先安装 pytorch
然后再安装 microsoft visual C++ build tools
```

运行

```sh
python test.py
python detect.py --weights weights/yolov5s.pt --source 0
```

## 制作自己的数据集

到 [网站](https://www.makesense.ai/) 制作

或者

### 安装工具

```sh
pip install labelimg
```

### 准备目录结构

```sh
./demo_training
├── data.yaml
├── train
│   ├── images
│   └── labels
└── validate
    ├── images
    └── labels
```

### 打标记

使用 labelImg 给图片打标记

存储格式使用 yolo 的

标记一张，保存一张，比较费时间

或者，从 [这里](https://public.roboflow.com/) 下载现有的模型

### 修改配置

cp data/coco128.yaml data/demo_training.yaml

修改

```sh
training 路径
nc 个数
names
```

### 修改 model 配置

修改 yolov5/models/yolov5s.yaml 里面的 nc 个数

## 开始训练

```sh
python train.py --img 640 --batch 16 --epoch 30 --data data/demo_training.yaml --cfg models/yolov5s.yaml --weights weights/yolov5s.pt
或者
python train.py --img 640 --batch 16 --epoch 30 --data data/demo_training.yaml --cfg models/yolov5s.yaml --weights ""
```

## 测试训练结果

```sh
python detect.py --weights ./weights/best.pt --source ./DSC00123.jpg
```
