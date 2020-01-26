#ifndef _FAL_CFG_H_
#define _FAL_CFG_H_

#include <rtconfig.h>
#include <board.h>

#define STM32_FLASH_START_ADRESS_16K STM32_FLASH_START_ADRESS
#define STM32_FLASH_START_ADRESS_64K (STM32_FLASH_END_ADDRESS - 64*3*1024)
#define STM32_FLASH_START_ADRESS_128K STM32_FLASH_START_ADRESS

#define FLASH_SIZE_GRANULARITY_16K 16*1024
#define FLASH_SIZE_GRANULARITY_64K 64*3*1024
#define FLASH_SIZE_GRANULARITY_128K 128*1024

extern const struct fal_flash_dev stm32_onchip_flash_64k;

/* flash device table */
#define FAL_FLASH_DEV_TABLE                                          \
{                                                                    \
    &stm32_onchip_flash_64k,                                           \
}
/* ====================== Partition Configuration ========================== */
#ifdef FAL_PART_HAS_TABLE_CFG
/* partition table */
#define FAL_PART_TABLE                                                              \
{                                                                                   \
    {FAL_PART_MAGIC_WORD, "elmfs",   "onchip_flash_64k",         0,    64*1024, 0}, \
    {FAL_PART_MAGIC_WORD, "lfs",     "onchip_flash_64k",     64*1024,  64*1024, 0}, \
    {FAL_PART_MAGIC_WORD, "falfs",   "onchip_flash_64k",    128*1024,  64*1024, 0}, \
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