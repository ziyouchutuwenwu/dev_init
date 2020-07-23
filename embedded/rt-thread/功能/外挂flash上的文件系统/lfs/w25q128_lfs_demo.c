#include <fal.h>
#include <dfs_fs.h>

/* 添加 DEBUG 头文件 */
#define DBG_SECTION_NAME               "main"
#define DBG_LEVEL                      DBG_INFO
#include <rtdbg.h>
/* 定义要使用的分区名字 */
#define FS_PARTITION_NAME              "filesystem"

int w25q128_lfs_demo(void)
{
    struct rt_device* mtd_dev = RT_NULL;

    fal_init();

    mtd_dev = fal_mtd_nor_device_create(FS_PARTITION_NAME);
    if ( !mtd_dev ){
        LOG_E("Can't create a mtd device on '%s' partition.", FS_PARTITION_NAME);
    }
    else{
        if (dfs_mount(FS_PARTITION_NAME, "/", "lfs", 0, 0) == 0){
            LOG_I("Filesystem initialized!");
        }
        else{
            dfs_mkfs("lfs", FS_PARTITION_NAME);

            if (dfs_mount(FS_PARTITION_NAME, "/", "lfs", 0, 0) == 0){
                LOG_I("Filesystem initialized!");
            }
            else{
                LOG_E("Failed to initialize filesystem!");
            }
        }
    }

    return RT_EOK;
}

MSH_CMD_EXPORT(w25q128_lfs_demo, w25q128_lfs_demo);