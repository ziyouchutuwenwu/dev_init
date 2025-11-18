# -*-coding:utf-8-*-

import paho.mqtt.client as mqtt
import time

unacked_sub = []

def on_connect(client, userdata, flags, rc):
    print("Connection returned with result code:" + str(rc))


def on_message(client, userdata, msg):
    print("Received message, topic: " + msg.topic + " payload: " + str(msg.payload))


def on_disconnect(client, userdata, rc):
    print("Disconnection returned result: " + str(rc))


def on_subscribe(client, userdata, mid, granted_qos):
    unacked_sub.remove(mid)


client = mqtt.Client()
client.on_connect = on_connect
client.on_disconnect = on_disconnect
client.on_message = on_message
client.on_subscribe = on_subscribe

client.connect("127.0.0.1", 1883, 60)

client.loop_start()

result, mid = client.subscribe("demo_topic", 0)
unacked_sub.append(mid)
result, mid = client.subscribe([("temperature", 0), ("humidity", 0)])
unacked_sub.append(mid)

while len(unacked_sub) != 0:
    time.sleep(1)

client.publish("demo_topic", payload="Hello world!")
client.publish("temperature", payload="24.0")
client.publish("humidity", payload="65%")

time.sleep(5)
client.loop_stop()
client.disconnect()
