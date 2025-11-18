# canopen

## 说明

linux 下 canopen

## 用法

### 测试虚拟设备

生成虚拟 can 设备

```sh
sudo modprobe vcan
sudo ip link add dev vcan0 type vcan
sudo ip link set up vcan0
```

收发数据

```sh
candump -t d vcan0
cansend vcan0 '123#abcdabcd'
```

### python 的相关库

```sh
pip install canard
pip install canopen
```
