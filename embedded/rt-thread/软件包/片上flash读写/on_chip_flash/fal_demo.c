#include <fal.h>
#include <rtdbg.h>

#define FS_PARTITION_NAME "fs"

int on_chip_fal_init(){
    fal_init();

    // 创建设备，list_device能看到
    struct rt_device* mtd_dev = RT_NULL;
    mtd_dev = fal_mtd_nor_device_create(FS_PARTITION_NAME);
    if (!mtd_dev){
        LOG_E("Can't create a mtd device on '%s' partition.", FS_PARTITION_NAME);
    }

    return 0;
}

int fal_demo(void)
{
    const struct fal_partition* partition = fal_partition_find(FS_PARTITION_NAME);

    fal_partition_erase_all(partition);
    // stm32_flash_erase(134447108, 2);
    // // fal_partition_erase(partition, 0x4, 2);

    char data_to_save[] = {0xa, 0xb};
    fal_partition_write(partition, 0x4, data_to_save, sizeof(data_to_save));

    char data_to_read[2] = {0};
    fal_partition_read(partition, 0x4, data_to_read, sizeof(data_to_read));

    // rt_kprintf("data :%c %c\n", data_to_read[0], data_to_read[1]);

    return RT_EOK;
}

MSH_CMD_EXPORT(fal_demo, fal_demo);

INIT_COMPONENT_EXPORT(on_chip_fal_init);