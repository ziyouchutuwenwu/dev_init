#include <board.h>

#define RESET_IO GET_PIN(H, 2)

void phy_reset(void)
{
    rt_pin_write(RESET_IO, PIN_LOW);
    rt_thread_mdelay(50);
    rt_pin_write(RESET_IO, PIN_HIGH);
}

int phy_init(void)
{
    rt_pin_mode(RESET_IO, PIN_MODE_OUTPUT);
    rt_pin_write(RESET_IO, PIN_HIGH);
    return RT_EOK;
}
INIT_BOARD_EXPORT(phy_init);
