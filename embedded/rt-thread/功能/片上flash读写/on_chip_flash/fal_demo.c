#include <fal.h>
#include <rtdbg.h>

#define DEMO_FS_PARTITION_NAME "falfs"

int fal_demo(void)
{
    const struct fal_partition* partition = fal_partition_find(DEMO_FS_PARTITION_NAME);

    fal_partition_erase(partition, 0x4, 2);

    char data_to_save[] = {0xa, 0xb};
    fal_partition_write(partition, 0x4, data_to_save, sizeof(data_to_save));

    char data_to_read[2] = {0};
    fal_partition_read(partition, 0x4, data_to_read, sizeof(data_to_read));

    // rt_kprintf("data :%c %c\n", data_to_read[0], data_to_read[1]);

    return RT_EOK;
}

MSH_CMD_EXPORT(fal_demo, fal_demo);

INIT_COMPONENT_EXPORT(fal_init);