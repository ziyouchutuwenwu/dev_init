#include <fal.h>
#include <dfs_fs.h>
#include <rtdbg.h>

/*
[I/FAL] ==================== FAL partition table ====================
[I/FAL] | name       | flash_dev |   offset   |    length  |
[I/FAL] -------------------------------------------------------------
[I/FAL] | filesystem | W25Q128   | 0x00000000 | 0x01000000 |
*/

#define FS_PARTITION_NAME "filesystem"
#define FS_DEVICE_NAME    "W25Q128"

int w25q128_elmfs_demo(void)
{
    fal_init();

    struct rt_device* mtd_dev = RT_NULL;
    mtd_dev = fal_mtd_nor_device_create(FS_PARTITION_NAME);
    if ( !mtd_dev ){
        LOG_E("Can't create a mtd device on '%s' partition.", FS_PARTITION_NAME);
    }
    else{
        // 以防万一，先unmount
        dfs_unmount("/");

        if (dfs_mount(FS_DEVICE_NAME, "/", "elm", 0, 0) == 0){
            LOG_I("Filesystem initialized!");
        }
        else{
            // mkfs -t elm W25Q128
            dfs_mkfs("elm", FS_DEVICE_NAME);

            if (dfs_mount(FS_DEVICE_NAME, "/", "elm", 0, 0) == 0){
                LOG_I("Filesystem initialized!");
            }
            else{
                LOG_E("Failed to initialize filesystem!");
            }
        }
    }

    return RT_EOK;
}

MSH_CMD_EXPORT(w25q128_elmfs_demo, w25q128_elmfs_demo);