#include <dfs_fs.h>
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

#define LFS_MOUNT_POINT     "/"
#define LFS_PARTITION_NAME  "lfs"
#define FS_DEVICE_NAME      LFS_PARTITION_NAME

int lfs_demo(void)
{
    fal_init();

    // 创建mtd设备，list_device能看到
    rt_device_t mtd_dev = RT_NULL;

    if ( rt_device_find(LFS_PARTITION_NAME) == RT_NULL){
        mtd_dev = fal_mtd_nor_device_create(LFS_PARTITION_NAME);
        if (!mtd_dev){
            LOG_E("Can't create a mtd device on '%s' partition.", LFS_PARTITION_NAME);
        }
    }

    dfs_unmount("/");

    if (dfs_mount(FS_DEVICE_NAME, LFS_MOUNT_POINT, "lfs", 0, 0) == 0){
        LOG_W("Filesystem initialized!");
    }
    else{
        LOG_W("%s not formatted, now formatting", LFS_PARTITION_NAME);
        dfs_mkfs("lfs", FS_DEVICE_NAME);

        if ( dfs_mount(FS_DEVICE_NAME, LFS_MOUNT_POINT, "lfs", 0, 0) == 0 ){
            LOG_W("Filesystem initialized!");
        }
        else{
            LOG_E("Failed to initialize filesystem!");
        }
    }

    return RT_EOK;
}

/*
mkfs -t lfs lfs
最后一个参数为通过 fal_blk_device_create 创建出来的 block device
*/
MSH_CMD_EXPORT(lfs_demo, lfs_demo);