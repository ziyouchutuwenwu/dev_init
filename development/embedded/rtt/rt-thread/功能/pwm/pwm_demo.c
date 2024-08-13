#include <rtthread.h>
#include <rtdevice.h>

#define PWM_DEV_NAME        "pwm2"
#define PWM_DEV_CHANNEL     4

struct rt_device_pwm *pwm_dev;

static int pwm_demo(int argc, char *argv[])
{
    rt_uint32_t period, pulse, dir;

    period = 10 * 1000 * 1000;
    pulse = 5 * 1000 * 1000;

    pwm_dev = (struct rt_device_pwm *)rt_device_find(PWM_DEV_NAME);
    if (pwm_dev == RT_NULL)
    {
        rt_kprintf("pwm demo run failed! can't find %s device!\n", PWM_DEV_NAME);
        return RT_ERROR;
    }

    rt_pwm_set(pwm_dev, PWM_DEV_CHANNEL, period, pulse);
    rt_pwm_enable(pwm_dev, PWM_DEV_CHANNEL);

    rt_thread_mdelay(2*1000);
    rt_pwm_disable(pwm_dev, PWM_DEV_CHANNEL);
}

MSH_CMD_EXPORT(pwm_demo, pwm demo);