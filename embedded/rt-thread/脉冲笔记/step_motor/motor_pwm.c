#include <rtthread.h>
#include <rtdevice.h>
#include <board.h>

/*
细分数为1, 一圈200个脉冲
假定需要2s，每秒脉冲100个
脉冲周期为1s/100=10ms，占空比一般50%
*/

#define PWM_DEV_NAME        "pwm2"
#define PWM_DEV_CHANNEL     4

#define PUL_SUB_PIN     GET_PIN(A, 7)

struct rt_device_pwm *pwm_dev;

void pwm_init()
{
    rt_uint32_t period, pulse;

    // 我也不知道这里为啥要除以4，这里不弄的话，时间需要*4
    period = 10*1000*1000/4;
    pulse = 5*1000*1000/4;

    rt_pin_mode(PUL_SUB_PIN, PIN_MODE_OUTPUT);
    pwm_dev = (struct rt_device_pwm *)rt_device_find(PWM_DEV_NAME);
    rt_pwm_set(pwm_dev, PWM_DEV_CHANNEL, period, pulse);
}

void pwm_start(){
    rt_pwm_enable(pwm_dev, PWM_DEV_CHANNEL);
}

void pwn_stop(){
    rt_pwm_disable(pwm_dev, PWM_DEV_CHANNEL);
    rt_device_close(pwm_dev);
}