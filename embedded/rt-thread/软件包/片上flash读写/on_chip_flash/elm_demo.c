#include <dfs_fs.h>
#include <fal.h>
#include <rtdbg.h>

#define ELM_FS_PARTITION_NAME "elmfs"

int elm_demo(void)
{
    // 创建块设备
    rt_device_t mtd_dev = RT_NULL;

    if ( rt_device_find(ELM_FS_PARTITION_NAME) == RT_NULL){
        mtd_dev = fal_blk_device_create(ELM_FS_PARTITION_NAME);
        if (!mtd_dev){
            LOG_E("Can't create a block device on '%s' partition.", ELM_FS_PARTITION_NAME);
        }
    }

    if (dfs_mount(ELM_FS_PARTITION_NAME, "/", "elm", 0, 0) == 0){
        LOG_W("Filesystem initialized!");
    }
    else{
        dfs_unmount("/");
        LOG_W("%s not formatted, now formatting", ELM_FS_PARTITION_NAME);
        dfs_mkfs("elm", ELM_FS_PARTITION_NAME);

        if ( dfs_mount(ELM_FS_PARTITION_NAME, "/", "elm", 0, 0) == 0 ){
            LOG_W("Filesystem initialized!");
        }
        else{
            LOG_E("Failed to initialize filesystem!");
        }
    }

    return RT_EOK;

    return RT_EOK;
}

// mkfs -t elm elmfs
MSH_CMD_EXPORT(elm_demo, elm_demo);