#ifndef _FAL_CFG_H_
#define _FAL_CFG_H_

#include <rtconfig.h>
#include <board.h>

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

extern const struct fal_flash_dev stm32_onchip_flash_64k;

/* flash device table */
#define FAL_FLASH_DEV_TABLE                                          \
{                                                                    \
    &stm32_onchip_flash_64k,                                           \
}
/* ====================== Partition Configuration ========================== */
#ifdef FAL_PART_HAS_TABLE_CFG

/* partition table
起始地址
长度
最后一个不知道
*/
#define FAL_PART_TABLE                                                              \
{                                                                                   \
    {FAL_PART_MAGIC_WORD, "elmfs",   "onchip_flash_64k",         0,    64*1024, 0}, \
    {FAL_PART_MAGIC_WORD, "lfs",     "onchip_flash_64k",     64*1024,  64*1024, 0}, \
    {FAL_PART_MAGIC_WORD, "falfs",   "onchip_flash_64k",    (64 + 64)*1024,  64*1024, 0}, \
}
#endif /* FAL_PART_HAS_TABLE_CFG */

#endif /* _FAL_CFG_H_ */

/*
{                                                                                   \
    {FAL_PART_MAGIC_WORD, "elmfs",   "onchip_flash_64k",         0,    64*1024, 0}, \
    {FAL_PART_MAGIC_WORD, "lfs",     "onchip_flash_64k",     64*1024,  64*1024, 0}, \
    {FAL_PART_MAGIC_WORD, "falfs",   "onchip_flash_64k",    128*1024,  64*1024, 0}, \
}
*/