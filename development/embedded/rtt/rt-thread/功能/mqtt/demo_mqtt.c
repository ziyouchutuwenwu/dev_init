#include <stdio.h>
#include <stdint.h>

#include "mqttclient.h"


static void on_message_receive(void* client, message_data_t* msg)
{
    (void) client;
    rt_kprintf("-----------------------------------------------------------------------------------");
    rt_kprintf("%s:%d %s()...\ntopic: %s\nmessage:%s", __FILE__, __LINE__, __FUNCTION__, msg->topic_name, (char*)msg->message->payload);
    rt_kprintf("-----------------------------------------------------------------------------------");
}


static int mqtt_say_hello(mqtt_client_t *client)
{
    mqtt_message_t msg;
    memset(&msg, 0, sizeof(msg));

    msg.qos = 0;
    msg.payload = (void *) "payload to sent";

    return mqtt_publish(client, "demo_topic", &msg);
}


int mqtt_demo(void)
{
    mqtt_client_t *client = NULL;

    mqtt_log_init();

    client = mqtt_lease();

    mqtt_set_host(client, "192.168.88.234");
    mqtt_set_port(client, "1883");
    mqtt_set_clean_session(client, 1);
    mqtt_set_keep_alive_interval(client, 10);

    mqtt_connect(client);
    mqtt_subscribe(client, "demo_topic", QOS0, on_message_receive);

    while (1) {
        mqtt_say_hello(client);
        mqtt_sleep_ms(4 * 1000);
    }
}

MSH_CMD_EXPORT(mqtt_demo, mqtt_demo);