#include <dfs_fs.h>
#include <fal.h>
#include <rtdbg.h>

#define LFS_PARTITION_NAME "littlefs"

int lfs_demo(void)
{
    // 创建mtd设备，list_device能看到
    struct rt_device* mtd_dev = RT_NULL;
    mtd_dev = fal_mtd_nor_device_create(LFS_PARTITION_NAME);
    if (!mtd_dev){
        LOG_E("Can't create a mtd device on '%s' partition.", LFS_PARTITION_NAME);
    }

    if (dfs_mount(LFS_PARTITION_NAME, "/", "lfs", 0, 0) == 0){
        LOG_I("Filesystem initialized!");
    }
    else{
        LOG_E("%s not formatted, now formatting", LFS_PARTITION_NAME);
        dfs_mkfs("lfs", LFS_PARTITION_NAME);
        if (dfs_mount(LFS_PARTITION_NAME, "/lfs", "lfs", 0, 0) == 0){
            LOG_I("Filesystem initialized!");
        }
        else{
            LOG_E("Failed to initialize filesystem!");
        }
    }

    return RT_EOK;
}

// mkfs -t lfs littlefs
MSH_CMD_EXPORT(lfs_demo, lfs_demo);