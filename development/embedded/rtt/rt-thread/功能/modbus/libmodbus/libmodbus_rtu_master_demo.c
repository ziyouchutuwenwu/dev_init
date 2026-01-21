#include <rtthread.h>
#include <rtdevice.h>
#include <modbus.h>

static void rtu_master_demo_thread(void *param){
    uint16_t tab_reg[64] = {0};
    modbus_t* ctx = RT_NULL;

    ctx = modbus_new_rtu("/dev/uart5", 115200, 'N', 8, 1);
    modbus_rtu_set_serial_mode(ctx, MODBUS_RTU_RS232);
    modbus_set_slave(ctx, 3);
    modbus_connect(ctx);
    modbus_set_response_timeout(ctx, 0, 1000000);
    int num = 0;
    while (1)
    {
        memset(tab_reg, 0, 64 * 2);
        int regs = modbus_read_registers(ctx, 0, 20, tab_reg);
        printf("-------------------------------------------\n");
        printf("[%4d][read num = %d]", num, regs);
        num++;
        int i;
        for (i = 0; i < 20; i++)
        {
            printf("<%#x>", tab_reg[i]);
        }
        printf("\n");
        printf("-------------------------------------------\n");
        rt_thread_mdelay(2000);
    }

    modbus_close(ctx);
    modbus_free(ctx);
}

int libmodbus_rtu_master_demo(){
    rt_thread_t tid;
    tid = rt_thread_create("rtu_master_demo",
                           rtu_master_demo_thread, RT_NULL,
                           2048,
                           12, 10);
    if (tid != RT_NULL) rt_thread_startup(tid);
    return RT_EOK;
}

MSH_CMD_EXPORT(libmodbus_rtu_master_demo, libmodbus_rtu_master_demo)