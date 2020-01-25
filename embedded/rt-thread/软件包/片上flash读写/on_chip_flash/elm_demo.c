#include <dfs_fs.h>
#include <fal.h>
#include <rtdbg.h>

#define ELM_FS_PARTITION_NAME "elmfs"

int elm_demo(void)
{
    // 创建块设备
    struct rt_device *flash_dev = fal_blk_device_create(ELM_FS_PARTITION_NAME);
    if (flash_dev == NULL) {
        LOG_E("Can't create a block device on '%s' partition.", ELM_FS_PARTITION_NAME);
    }
    else{
        LOG_D("Create a block device on the %s partition of flash successful.", ELM_FS_PARTITION_NAME);
    }

    if (dfs_mount(ELM_FS_PARTITION_NAME, "/", "elm", 0, 0) == 0){
        LOG_I("Filesystem initialized!");
    }
    else{
        LOG_E("%s not formatted, now formatting", ELM_FS_PARTITION_NAME);
        dfs_mkfs("elm", ELM_FS_PARTITION_NAME);

        if (dfs_mount(ELM_FS_PARTITION_NAME, "/elm", "elm", 0, 0) == 0){
            LOG_I("Filesystem initialized!");
        }
        else{
            LOG_E("Failed to initialize filesystem!");
        }
    }

    return RT_EOK;
}

// mkfs -t elm elmfs
MSH_CMD_EXPORT(elm_demo, elm_demo);