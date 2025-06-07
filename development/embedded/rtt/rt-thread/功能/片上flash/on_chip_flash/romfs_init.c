#include <dfs_fs.h>
#include <rtdbg.h>

extern const struct romfs_dirent romfs_root;
#define DFS_ROMFS_ROOT          (&romfs_root)

int romfs_init(void)
{
    /* mount ROMFS as root directory */
    if (dfs_mount( RT_NULL, "/", "rom", 0, (const void *)DFS_ROMFS_ROOT) == 0)
    {
        rt_kprintf("ROMFS File System initialized!\n");
    }
    else
    {
        rt_kprintf("ROMFS File System initialized Failed!\n");
    }

    return RT_EOK;
}

INIT_ENV_EXPORT(romfs_init);