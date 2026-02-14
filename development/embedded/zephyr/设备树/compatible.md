# compatible

## 说明

用于生成软件层 device, 用于和系统通信

## 写法

### 隔离

compatible 是独立的

```c
audio_chip {
    compatible = "vendor1,audio1";

    // 这里无论写不写 compatible， 都不会使用上层的 compatible
    dac {
        compatible = "vendor2,dac1";
    };
};
```

### 位置

独立设备

```c
dac1 {
    // 每个节点写自己的 compatible
    compatible = "myvendor,my-dac";
};
```

容器型设备

```c
leds {
    // 不能写在设备节点
    // 必须在父节点写 compatible
    compatible = "gpio-leds";

    led0: led_0 {
        gpios = <&gpio48 0 GPIO_ACTIVE_HIGH>;
        label = "board led";
    };
    led1: led_1 {
        gpios = <&gpio49 0 GPIO_ACTIVE_HIGH>;
        label = "board led 2";
    };
};
```
