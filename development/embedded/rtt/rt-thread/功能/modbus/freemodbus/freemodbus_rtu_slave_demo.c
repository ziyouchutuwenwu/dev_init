#include <rtthread.h>
#include <mb.h>
#include <mb_m.h>
#include <user_mb_app.h>

#define MB_POLL_THREAD_PRIORITY  10
#define MB_SEND_THREAD_PRIORITY  RT_THREAD_PRIORITY_MAX - 1

extern USHORT usSRegHoldBuf[S_REG_HOLDING_NREGS];

// master来读取slave的数据
static void rtu_slave_demo_thread(void *parameter)
{
    USHORT*           usRegHoldingBuf;
    usRegHoldingBuf = usSRegHoldBuf;
    rt_base_t level;

    while (1){
        level = rt_hw_interrupt_disable();

        usRegHoldingBuf[3] = (USHORT)(rt_tick_get() / 100);

        rt_hw_interrupt_enable(level);

        rt_thread_mdelay(1000);
    }
}

static void modbus_slave_poll(void *parameter)
{
    // 从机地址1, uart5
    eMBInit(MB_RTU, 1, 5, 115200, MB_PAR_EVEN);
    eMBEnable();
    while (1)
    {
        eMBPoll();
        rt_thread_mdelay(200);
    }
}
int freemodbus_rtu_slave_demo(){
    static rt_uint8_t is_init = 0;
    rt_thread_t tid1 = RT_NULL, tid2 = RT_NULL;

    if (is_init > 0){
        rt_kprintf("sample is running\n");
        return -RT_ERROR;
    }
    tid1 = rt_thread_create("modbus_slave_poll", modbus_slave_poll, RT_NULL, 512, MB_POLL_THREAD_PRIORITY, 10);
    if (tid1 != RT_NULL){
        rt_thread_startup(tid1);
    }
    else{
        goto __exit;
    }

    tid2 = rt_thread_create("rtu_slave_demo_thread", rtu_slave_demo_thread, RT_NULL, 512, MB_SEND_THREAD_PRIORITY, 10);
    if (tid2 != RT_NULL){
        rt_thread_startup(tid2);
    }
    else{
        goto __exit;
    }

    is_init = 1;
    return RT_EOK;

__exit:
    if (tid1) rt_thread_delete(tid1);

    if (tid2) rt_thread_delete(tid2);

    return -RT_ERROR;
}

MSH_CMD_EXPORT(freemodbus_rtu_slave_demo, freemodbus_rtu_slave_demo)