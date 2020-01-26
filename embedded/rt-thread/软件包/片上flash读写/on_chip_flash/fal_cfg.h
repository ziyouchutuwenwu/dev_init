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

#define FLASH_SECTOR_0     0U  /*!< Sector Number 0   */
#define FLASH_SECTOR_1     1U  /*!< Sector Number 1   */
#define FLASH_SECTOR_2     2U  /*!< Sector Number 2   */
#define FLASH_SECTOR_3     3U  /*!< Sector Number 3   */
#define FLASH_SECTOR_4     4U  /*!< Sector Number 4   */
#define FLASH_SECTOR_5     5U  /*!< Sector Number 5   */
#define FLASH_SECTOR_6     6U  /*!< Sector Number 6   */
#define FLASH_SECTOR_7     7U  /*!< Sector Number 7   */
#define FLASH_SECTOR_8     8U  /*!< Sector Number 8   */
#define FLASH_SECTOR_9     9U  /*!< Sector Number 9   */
#define FLASH_SECTOR_10    10U /*!< Sector Number 10  */
#define FLASH_SECTOR_11    11U /*!< Sector Number 11  */
#define FLASH_SECTOR_12    12U /*!< Sector Number 12  */
#define FLASH_SECTOR_13    13U /*!< Sector Number 13  */
#define FLASH_SECTOR_14    14U /*!< Sector Number 14  */
#define FLASH_SECTOR_15    15U /*!< Sector Number 15  */
#define FLASH_SECTOR_16    16U /*!< Sector Number 16  */
#define FLASH_SECTOR_17    17U /*!< Sector Number 17  */
#define FLASH_SECTOR_18    18U /*!< Sector Number 18  */
#define FLASH_SECTOR_19    19U /*!< Sector Number 19  */
#define FLASH_SECTOR_20    20U /*!< Sector Number 20  */
#define FLASH_SECTOR_21    21U /*!< Sector Number 21  */
#define FLASH_SECTOR_22    22U /*!< Sector Number 22  */
#define FLASH_SECTOR_23    23U /*!< Sector Number 23  */

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