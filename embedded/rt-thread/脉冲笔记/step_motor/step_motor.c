#include "motor_pwm.h"
#include "motor_timer.h"

#include <rtthread.h>
#include <rtdevice.h>

static void step_motor_init(){
	hwtimer_init();
	pwm_init();
}

static void step_motor_start(){
	hwtimer_start();
	pwm_start();
}

static void step_motor_stop(){
	hwtimer_stop();
	pwn_stop();
}

MSH_CMD_EXPORT(step_motor_init, step motor init);
MSH_CMD_EXPORT(step_motor_start, step motor start);
MSH_CMD_EXPORT(step_motor_stop, step motor stop);

static void test(){
	step_motor_init();
	step_motor_start();
}
MSH_CMD_EXPORT(test, test);