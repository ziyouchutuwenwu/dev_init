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

#define ELM_FS_MOUNT_POINT      "/"
#define ELM_FS_PARTITION_NAME   "elmfs"

// fal_blk_device_create 会创建一个和分区名一样的device
#define FS_DEVICE_NAME          ELM_FS_PARTITION_NAME

int elm_demo(void)
{
    fal_init();

    rt_device_t mtd_dev = RT_NULL;
    if ( rt_device_find(ELM_FS_PARTITION_NAME) == RT_NULL){
        mtd_dev = fal_blk_device_create(ELM_FS_PARTITION_NAME);
        if (!mtd_dev){
            LOG_E("Can't create a block device on '%s' partition.", ELM_FS_PARTITION_NAME);
        }
    }

    dfs_unmount("/");

    if (dfs_mount(FS_DEVICE_NAME, ELM_FS_MOUNT_POINT, "elm", 0, 0) == 0){
        LOG_W("Filesystem initialized!");
    }
    else{
        LOG_W("%s not formatted, now formatting", ELM_FS_PARTITION_NAME);
        dfs_mkfs("elm", FS_DEVICE_NAME);

        if ( dfs_mount(FS_DEVICE_NAME, ELM_FS_MOUNT_POINT, "elm", 0, 0) == 0 ){
            LOG_W("Filesystem initialized!");
        }
        else{
            LOG_E("Failed to initialize filesystem!");
        }
    }

    return RT_EOK;
}
/*
mkfs -t elm elmfs
最后一个参数为通过 fal_blk_device_create 创建出来的 block device
*/
MSH_CMD_EXPORT(elm_demo, elm_demo);