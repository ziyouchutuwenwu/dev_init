#include <dfs_fs.h>
#include <fal.h>
#include <rtdbg.h>

#define FS_PARTITION_NAME "fs"

int lfs_demo(void)
{
    if (dfs_mount(FS_PARTITION_NAME, "/", "lfs", 0, 0) == 0)
        {
            LOG_I("Filesystem initialized!");
        }
        else
        {
            /* 格式化文件系统 */
            dfs_mkfs("lfs", FS_PARTITION_NAME);
            /* 挂载 littlefs */
            if (dfs_mount(FS_PARTITION_NAME, "/", "lfs", 0, 0) == 0)
            {
                LOG_I("Filesystem initialized!");
            }
            else
            {
                LOG_E("Failed to initialize filesystem!");
            }
        }

    return RT_EOK;
}

// mkfs -t lfs fs
MSH_CMD_EXPORT(lfs_demo, lfs_demo);