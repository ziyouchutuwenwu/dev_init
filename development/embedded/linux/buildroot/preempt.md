# preempt

## 说明

就是配置实时性

## 步骤

```sh
make O=output linux-menuconfig
```

```sh
General setup  --->
  Preemption Model ()  --->
    (X) Preemptible Kernel (Low-Latency Desktop)
  Timers subsystem  --->
    [*] High Resolution Timer Support


Kernel Features  --->
  [*] Symmetric Multi-Processing
  Timer frequency ()  --->
    (X) 1000 Hz
```

还有两个宏，没有找到设置的地方，默认都是 y

```sh
# 将中断处理改成线程化，提高 Low-Latency 响应，多核必选
CONFIG_IRQ_FORCED_THREADING
# 允许 RCU 被抢占，防止阻塞调度，Low-Latency 默认选中
CONFIG_PREEMPT_RCU
```
