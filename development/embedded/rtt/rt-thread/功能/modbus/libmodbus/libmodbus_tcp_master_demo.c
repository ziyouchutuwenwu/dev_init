#include <rtthread.h>
#include <rtdevice.h>
#include <modbus.h>
#include <sal_socket.h>

static void tcp_master_demo_thread(void *param)
{
    uint16_t tab_reg[64] = {0};
    modbus_t *ctx = RT_NULL;

    ctx = modbus_new_tcp("192.168.88.61", 502, AF_INET);
    modbus_set_slave(ctx, 3);
    modbus_set_response_timeout(ctx, 0, 1000000);
_modbus_tcp_start:
    if(modbus_connect(ctx) < 0)  goto _modbus_tcp_restart;

    int num = 0;
    while (1)
    {
        memset(tab_reg, 0, 64 * 2);
        int regs = modbus_read_registers(ctx, 0, 20, tab_reg);
        if(regs < 0) goto _modbus_tcp_restart;

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
        rt_thread_mdelay(1000);
    }

_modbus_tcp_restart:
    modbus_close(ctx);
    rt_thread_mdelay(2000);
    goto _modbus_tcp_start;

    modbus_free(ctx);
}

int libmodbus_tcp_master_demo(){
    rt_thread_t tid;
    tid = rt_thread_create("tcp_master_demo",
                           tcp_master_demo_thread, RT_NULL,
                           2048,
                           12, 10);
    if (tid != RT_NULL) rt_thread_startup(tid);
    return RT_EOK;
}

MSH_CMD_EXPORT(libmodbus_tcp_master_demo, libmodbus_tcp_master_demo)