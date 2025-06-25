# 外挂 flash

## 说明

外挂 flash 读写
参考[这里](https://www.rt-thread.org/document/site/application-note/components/sfud/an0048-sfud/)

## 配置

### cubeMX

根据原理图，找到相应的 spi 脚，配置引脚

### Kconfig

```sh
menuconfig BSP_USING_SPI
    bool "Enable SPI BUS"
    default n
    select RT_USING_SPI
    if BSP_USING_SPI
        config BSP_USING_SPI2
            bool "Enable SPI2 BUS"
            default n

        config BSP_SPI2_TX_USING_DMA
            bool "Enable SPI2 TX DMA"
            depends on BSP_USING_SPI2
            default n

        config BSP_SPI2_RX_USING_DMA
            bool "Enable SPI1 RX DMA"
            depends on BSP_USING_SPI2
            select BSP_SPI2_TX_USING_DMA
            default n
    endif
```

Kconfig 的 `"Onboard Peripheral Drivers"` 添加

```sh
config BSP_USING_QSPI_FLASH
    bool "Enable QSPI FLASH (W25Q128 spi10)"
    select BSP_USING_QSPI
    select RT_USING_SFUD
    select RT_SFUD_USING_QSPI
    default n
```

### menuconfig

```sh
Hardware Drivers Config > Onboard Peripheral Drivers
  [*] Enable QSPI FLASH (W25Q128 spi10)

RT-Thread Components > Device Drivers
  [*] Using MTD Nor Flash device drivers

RT-Thread online packages >
 system packages >
  [*] fal: Flash Abstraction Layer implement. Manage flash device and partition.  --->
    (W25Q128) The name of the device used by FAL
    这是 SFUD 初始化 flash 后创建的设备名

Hardware Drivers Config > On-chip Peripheral Drivers > Enable SPI BUS
  [*] Enable SPI BUS  --->
    [*]   Enable SPI2 BUS
    -*-     Enable SPI2 TX DMA
    [*]     Enable SPI1 RX DMA

RT-Thread Components > Device Drivers
  [*] Using SPI Bus/Device device drivers
  -*- Enable QSPI mode
  -*- Using Serial Flash Universal Driver
  [*] Using auto probe flash JEDEC SFDP parameter
  [*] Using defined supported flash chip information table
  -*- Using QSPI mode support
  (50000000) Default spi maximum speed(HZ)
```

## 测试

```sh
msh />list_device
device           type         ref count
-------- -------------------- ----------
W25Q128  Block Device         0
spi10    SPI Device           0
e0       Network Interface    0
spi2     SPI Bus              0
uart1    Character Device     2
pin      Miscellaneous Device 0
```

```sh
msh />sf probe spi10
msh />sf erase 0 10
msh />sf read 0 10
msh />sf bench yes
```

## 注意

Flash 先擦后写
写入之前请先擦除，这是 flash 特性决定的，因为 flash 的编程原理就是只能将 1 写为 0，而不能将 0 写为 1。擦除动作就是相应的页 / 块的所有位变为 1（所有字节均为 0xFF），所以不擦除直接写入会有问题。
