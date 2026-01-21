#include <rtthread.h>
#include <rtdevice.h>

#define PWM_DEV_NAME        "pwm1"      // 硬件定时器设备名
#define PWM_CHANNEL1        1           // 通道1
#define PWM_CHANNEL2        2           // 通道2

struct rt_device_pwm *pwm_dev;

static int pwm_demo(int argc, char *argv[])
{
    rt_uint32_t period, pulse1, pulse2;

    pwm_dev = (struct rt_device_pwm *)rt_device_find(PWM_DEV_NAME);
    if (pwm_dev == RT_NULL)
    {
        rt_kprintf("can't find %s device!\n", PWM_DEV_NAME);
        return -1;
    }

    // 2. 设置周期和脉宽（单位：纳秒）
    period = 50000;      // 20kHz = 1s/20000 = 50,000ns
    pulse1 = period * 30 / 100; // 30% 占空比
    pulse2 = period * 60 / 100; // 60% 占空比

    // 3. 配置 PWM 通道1
    rt_pwm_set(pwm_dev, PWM_CHANNEL1, period, pulse1);
    rt_pwm_enable(pwm_dev, PWM_CHANNEL1);

    // 4. 配置 PWM 通道2
    rt_pwm_set(pwm_dev, PWM_CHANNEL2, period, pulse2);
    rt_pwm_enable(pwm_dev, PWM_CHANNEL2);

    return 0;
}

MSH_CMD_EXPORT(pwm_demo, pwm demo);