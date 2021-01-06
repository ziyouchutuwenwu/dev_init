#include <rtthread.h>
#include <rtdevice.h>
#include <board.h>

static int w25q128_auto_init(void)
{
    __HAL_RCC_GPIOB_CLK_ENABLE();

    // 最后俩参数是spi接口的cs脚
    rt_hw_spi_device_attach("spi2", "spi10", GPIOI, GPIO_PIN_0);

    if (RT_NULL == rt_sfud_flash_probe("W25Q128", "spi10"))
    {
        return -RT_ERROR;
    };

    return RT_EOK;
}
/* 导出到自动初始化 */
INIT_COMPONENT_EXPORT(w25q128_auto_init);