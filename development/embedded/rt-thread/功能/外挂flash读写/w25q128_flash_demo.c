#include <rtthread.h>
#include <rtdevice.h>
#include <board.h>
#include <sfud.h>

#define SPI_FLASH_DEVICE_NAME "spi10"

void w25q128_flash_demo(void)
{
    sfud_err result;
    uint8_t* read_data;
    uint8_t* write_data;
    sfud_flash* sfud_dev = NULL;

    sfud_dev = rt_sfud_flash_find(SPI_FLASH_DEVICE_NAME);
    // 或者 sfud_dev = rt_sfud_flash_find_by_dev_name("W25Q128");

    sfud_erase(sfud_dev, 0, 4096);

    write_data = rt_malloc(32);
    rt_memset(write_data, 3, 32);
    sfud_write(sfud_dev, 0, 32, write_data);

    read_data = rt_malloc(32);
    sfud_read(sfud_dev, 0, 32, read_data);

    rt_kprintf("please run cmd to check result\r\n");
    rt_kprintf("sf probe %s\r\n", SPI_FLASH_DEVICE_NAME);
    rt_kprintf("sf read 0 32\r\n");
}

MSH_CMD_EXPORT(w25q128_flash_demo, w25q128_flash_demo);