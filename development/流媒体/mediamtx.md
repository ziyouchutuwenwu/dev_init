# mediamtx

## 说明

[官网](https://github.com/bluenviron/mediamtx)

流媒体网关，把某个输入，转换为很多种流媒体输出

## 用法

mediamtx.yml

```yaml
logLevel: info
logDestinations: [stdout]

readTimeout: 60s
writeTimeout: 60s

rtsp: true
rtspAddress: :8554
rtspTransports: [tcp]
rtspEncryption: "no"

# rtsp: yes
# rtspAddress: :8511

# webrtc: yes
# webrtcAddress: :8512

# rtmp: yes
# rtmpAddress: :8513

# hls: yes
# hlsAddress: :8514

# # 抗丢包，rtmp 替代者
# srt: yes
# srtAddress: :8515

rtmp: false
hls: false
webrtc: false
srt: false
moq: false

paths:
  file_01:
    runOnInit: ffmpeg -re -fflags +genpts -stream_loop -1 -i ../videos/13.mp4 -c copy -an -rtsp_transport tcp -f rtsp rtsp://localhost:$RTSP_PORT/$MTX_PATH

  file_02:
    runOnInit: ffmpeg -re -fflags +genpts -stream_loop -1 -i ../videos/14.mp4 -c copy -an -rtsp_transport tcp -f rtsp rtsp://localhost:$RTSP_PORT/$MTX_PATH

  file_03:
    runOnInit: ffmpeg -re -fflags +genpts -stream_loop -1 -i ../videos/16.mp4 -c copy -an -rtsp_transport tcp -f rtsp rtsp://localhost:$RTSP_PORT/$MTX_PATH
```

测试

```sh
ffplay -x800 rtsp://127.0.0.1:8554/file_01
```
