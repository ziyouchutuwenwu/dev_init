#ifndef _FAL_CFG_H_
#define _FAL_CFG_H_

#include <rtthread.h>
#include <board.h>

// 片上flash的编译需要
// 定义分区大小，暂时只看64k
#define PARTITION_SIZE 64

//起始地址
#define STM32_FLASH_START_ADRESS_64K (STM32_FLASH_END_ADDRESS - PARTITION_SIZE*3*1024)

//分区长度
#define FLASH_SIZE_GRANULARITY_64K 64*3*1024

// 这些必须要定义，否则编译错误
#define STM32_FLASH_START_ADRESS_16K STM32_FLASH_START_ADRESS
#define STM32_FLASH_START_ADRESS_128K STM32_FLASH_START_ADRESS

#define FLASH_SIZE_GRANULARITY_16K 16*1024
#define FLASH_SIZE_GRANULARITY_128K 128*1024
// ---------------------

// F4系列得用这个64k的
#if defined(BSP_USING_ON_CHIP_FLASH)
extern const struct fal_flash_dev stm32_onchip_flash_64k;
#endif /* BSP_USING_ON_CHIP_FLASH */

#if defined(BSP_USING_QSPI_FLASH)
extern struct fal_flash_dev nor_flash0;
#endif /* BSP_USING_QSPI_FLASH */

/* ========================= Device Configuration ========================== */
#ifdef BSP_USING_ON_CHIP_FLASH
#define ONCHIP_FLASH_DEV     &stm32_onchip_flash_64k,
#else
#define ONCHIP_FLASH_DEV
#endif /* BSP_USING_ON_CHIP_FLASH */

#ifdef BSP_USING_QSPI_FLASH
#define SPI_FLASH_DEV        &nor_flash0,
#else
#define SPI_FLASH_DEV
#endif /* BSP_USING_QSPI_FLASH */

/* flash device table */
#define FAL_FLASH_DEV_TABLE                                          \
{                                                                    \
    ONCHIP_FLASH_DEV                                                 \
    SPI_FLASH_DEV                                                    \
}

/* ====================== Partition Configuration ========================== */
#ifdef FAL_PART_HAS_TABLE_CFG

// 片上flash的设备名onchip_flash_64k是驱动里面定义好的，不能随便改
#ifdef BSP_USING_ON_CHIP_FLASH
    #define ONCHIP_FLASH_PATITION      {FAL_PART_MAGIC_WROD, "elmfs",      "onchip_flash_64k", 0,         64 * 1024, 0},      \
                                       {FAL_PART_MAGIC_WROD, "lfs",        "onchip_flash_64k", 64* 1024,  64 * 1024, 0},      \
                                       {FAL_PART_MAGIC_WROD, "fal_onchip", "onchip_flash_64k", 128* 1024, 64 * 1024, 0},
#else
#define ONCHIP_FLASH_PATITION
#endif

#ifdef BSP_USING_QSPI_FLASH
#define SPI_FLASH_PARTITION            {FAL_PART_MAGIC_WROD, "filesystem", "W25Q128", 9 * 1024 * 1024, 16 * 1024 * 1024, 0},
#else
#define SPI_FLASH_PARTITION
#endif

/* partition table */
#define FAL_PART_TABLE                                               \
{                                                                    \
    ONCHIP_FLASH_PATITION                                            \
    SPI_FLASH_PARTITION                                              \
}
#endif /* FAL_PART_HAS_TABLE_CFG */

#endif /* _FAL_CFG_H_ */
