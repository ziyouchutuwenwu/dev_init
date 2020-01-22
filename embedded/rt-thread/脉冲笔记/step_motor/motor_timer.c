#include <rtthread.h>
#include <rtdevice.h>
#include "motor_timer.h"
#include "motor_pwm.h"

#define HWTIMER_DEV_NAME   "timer11"

static  rt_device_t hw_dev = RT_NULL;

static rt_err_t timeout_callback(rt_device_t dev, rt_size_t size)
{
    static int count = 0;
    count++;
    // rt_kprintf("count %d tick is :%d !\n", count, rt_tick_get());

    /*
    多次
        200/8，10000次，约50分钟
    单次
        需要的脉冲计数=脉冲总数/800，100w则为200*1250
        总时间为 脉冲总数*2/800
    */
    if ( count >= 200*12500 ){
        count = 0;
        pwn_stop();
        hwtimer_stop();

        // 单次模式启用这句话
        rt_kprintf("pwm finished!\n");
    }

    return 0;
}

void hwtimer_init(){
    rt_hwtimer_mode_t mode;

    hw_dev = rt_device_find(HWTIMER_DEV_NAME);
    rt_device_open(hw_dev, RT_DEVICE_OFLAG_RDWR);
    rt_device_set_rx_indicate(hw_dev, timeout_callback);

    mode = HWTIMER_MODE_PERIOD;
    rt_device_control(hw_dev, HWTIMER_CTRL_MODE_SET, &mode);

    return;
}

void hwtimer_start(){
    rt_hwtimerval_t timeout_s;

    timeout_s.sec = 0;
    timeout_s.usec = 10*1000;
    rt_device_write(hw_dev, 0, &timeout_s, sizeof(timeout_s)) != sizeof(timeout_s);
}

void hwtimer_stop(){
    rt_device_control(hw_dev, HWTIMER_CTRL_STOP, NULL);
    rt_device_close(hw_dev);
}
