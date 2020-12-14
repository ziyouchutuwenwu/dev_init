# mqtt 的例子

目前使用的是 kawaii-mqtt

## 服务器

```sh
docker run --rm -d --name emqx -p 1883:1883 -p 8083:8083 -p 8883:8883 -p 8084:8084 -p 18083:18083 emqx/emqx:v3.1.1
```

说明：

```sh
1883 MQTT 端口
8883 MQTT / SSL 端口
8083 MQTT / WebSocket 端口
8084 MQTT / WebSocket / SSL 端口
8080 HTTP 管理 API 端口
18083 Web 仪表板端口
```

管理后台

```sh
http://127.0.0.1:18083
admin
public
```

## rt-thread 的配置

```sh
RT-Thread online packages >
  IoT - internet of things
    [*] kawaii-mqtt: a mqtt client based on the socket API, support QoS2, mbedtls
    [*] using SAL

RT-Thread Components >
  Network > Socket abstraction layer
    [*] Enable BSD socket operated by file system API
```

## esp8266 可以连

## LAN8720A 很稳定

## 目前 w5500 各种连不上

错误信息如下：
[E/wiz.socket] WIZnet socket(0) receive data failed(-7).
