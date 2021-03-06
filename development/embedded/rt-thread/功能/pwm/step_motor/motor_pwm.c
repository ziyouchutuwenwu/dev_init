#include <rtthread.h>
#include <rtdevice.h>

/*
电机参数：
    细分数为4, 一圈800个脉冲
需求：
    假定需要2s，每秒脉冲400个
结果：
    脉冲周期为1s/400=2.5ms，占空比一般50%
*/

#define PWM_DEV_NAME        "pwm2"
#define PWM_DEV_CHANNEL     4

struct rt_device_pwm *pwm_dev;

void pwm_init()
{
    rt_uint32_t period, pulse;

    period = 10*1000*1000/4;
    pulse = 5*1000*1000/4;
    // 2500000.0
    // 1250000

    pwm_dev = (struct rt_device_pwm *)rt_device_find(PWM_DEV_NAME);
    rt_pwm_set(pwm_dev, PWM_DEV_CHANNEL, period, pulse);
}

void pwm_start(){
    rt_pwm_enable(pwm_dev, PWM_DEV_CHANNEL);
}

void pwn_stop(){
    rt_pwm_disable(pwm_dev, PWM_DEV_CHANNEL);
    rt_device_close((rt_device_t)pwm_dev);
}