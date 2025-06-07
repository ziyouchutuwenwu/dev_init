#include <fal.h>
#include <rtdbg.h>

/*
[I/FAL] ==================== FAL partition table ====================
[I/FAL] | name       | flash_dev        |   offset   |    length  |
[I/FAL] -------------------------------------------------------------
[I/FAL] | elmfs      | onchip_flash_64k | 0x00000000 | 0x00010000 |
[I/FAL] | lfs        | onchip_flash_64k | 0x00010000 | 0x00010000 |
[I/FAL] | fal_onchip | onchip_flash_64k | 0x00020000 | 0x00010000 |
[I/FAL] | filesystem | W25Q128          | 0x00900000 | 0x01000000 |
[I/FAL] =============================================================
*/

#define DEMO_FLASH_PARTITION_NAME "fal_onchip"

int fal_demo(void)
{
    fal_init();

    const struct fal_partition* partition = fal_partition_find(DEMO_FLASH_PARTITION_NAME);

    fal_partition_erase(partition, 0x4, 2);

    char data_to_save[] = {0xa, 0xb};
    fal_partition_write(partition, 0x4, data_to_save, sizeof(data_to_save));

    // char data_to_read[2] = {0};
    // fal_partition_read(partition, 0x4, data_to_read, sizeof(data_to_read));

    // char hex_str_data_array[2] = {0};
    // hex_to_str(data_to_read, sizeof(data_to_read), hex_str_data_array);
    // rt_kprintf("data :%s\n", hex_str_data_array);

    rt_kprintf("please run cmd to check result\r\n");
    rt_kprintf("fal probe %s\r\n", DEMO_FLASH_PARTITION_NAME);
    rt_kprintf("fal read 4 2\r\n");

    return RT_EOK;
}

MSH_CMD_EXPORT(fal_demo, fal_demo);