#include <rtthread.h>
#include <mb.h>
#include <mb_m.h>

#define MB_POLL_THREAD_PRIORITY  10
#define MB_SEND_THREAD_PRIORITY  RT_THREAD_PRIORITY_MAX - 1

static void rtu_master_demo_thread(void *parameter) {
    eMBMasterReqErrCode error_code = MB_MRE_NO_ERR;
    rt_uint16_t error_count = 0;
    USHORT data[2] = {0};

    while (1){
        data[0] = (USHORT)(rt_tick_get() / 10);
        data[1] = (USHORT)(rt_tick_get() % 10);

        error_code = eMBMasterReqWriteMultipleHoldingRegister(
            1,     /* salve address */
            2,     /* register start address */
            2,     /* register total number */
            data,  /* data to be written */
            RT_WAITING_FOREVER); /* timeout */

        /* Record the number of errors */
        if (error_code != MB_MRE_NO_ERR)
        {
            error_count++;
        }
    }
}

static void modbus_master_poll(void *parameter){
    // uart5
    eMBMasterInit(MB_RTU, 5, 115200, MB_PAR_EVEN);
    eMBMasterEnable();

    while (1){
        eMBMasterPoll();
        rt_thread_mdelay(500);
    }
}

int freemodbus_rtu_master_demo(){
    static rt_uint8_t is_init = 0;
    rt_thread_t tid1 = RT_NULL, tid2 = RT_NULL;

    if (is_init > 0){
        rt_kprintf("libmodbus_rtu_master is running\n");
        return -RT_ERROR;
    }
    tid1 = rt_thread_create("modbus_master_poll", modbus_master_poll, RT_NULL, 512, MB_POLL_THREAD_PRIORITY, 10);
    if (tid1 != RT_NULL){
        rt_thread_startup(tid1);
    }
    else{
        goto __exit;
    }

    tid2 = rt_thread_create("rtu_master_demo_thread", rtu_master_demo_thread, RT_NULL, 512, MB_SEND_THREAD_PRIORITY, 10);
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

MSH_CMD_EXPORT(freemodbus_rtu_master_demo, freemodbus_rtu_master_demo)