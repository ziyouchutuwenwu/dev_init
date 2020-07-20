# -*-coding:utf-8-*-

# Import paho-mqtt Client class:
import paho.mqtt.client as mqtt
import time

unacked_sub = []  # a list for unacknowledged subscription

# Define the callback to handle CONNACK from the broker, if the connection created normal, the value of rc is 0
def on_connect(client, userdata, flags, rc):
    print("Connection returned with result code:" + str(rc))


# Define the callback to hande publish from broker, here we simply print out the topic and payload of the received message
def on_message(client, userdata, msg):
    print("Received message, topic: " + msg.topic + " payload: " + str(msg.payload))


# Callback handles disconnection, print the rc value
def on_disconnect(client, userdata, rc):
    print("Disconnection returned result: " + str(rc))


# Remove the message id from the list for unacknowledged subscription
def on_subscribe(client, userdata, mid, granted_qos):
    unacked_sub.remove(mid)


# Create an instance of `Client`
client = mqtt.Client()
client.on_connect = on_connect
client.on_disconnect = on_disconnect
client.on_message = on_message
client.on_subscribe = on_subscribe

# Connect to broker
# connect() is blocking, it returns when the connection is successful or failed. If you want client connects in a non-blocking way, you may use connect_async() instead
client.connect("127.0.0.1", 1883, 60)

client.loop_start()

# Subscribe to a single topic
result, mid = client.subscribe("demo_topic", 0)
unacked_sub.append(mid)
# Subscribe to multiple topics
result, mid = client.subscribe([("temperature", 0), ("humidity", 0)])
unacked_sub.append(mid)

while len(unacked_sub) != 0:
    time.sleep(1)

client.publish("demo_topic", payload="Hello world!")
client.publish("temperature", payload="24.0")
client.publish("humidity", payload="65%")

# Disconnection
time.sleep(5)
client.loop_stop()
client.disconnect()
